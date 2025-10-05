import AppKit
import Carbon
import Combine
import DynamicNotchKit
import Foundation
import MachPort
import SwiftUI

protocol CommandRunning {
  func serialRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool,
                 machPortEvent: MachPortEvent, repeatingEvent: Bool) -> Task<Void, any Error>
  func concurrentRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool,
                     machPortEvent: MachPortEvent, repeatingEvent: Bool)
}

class CommandRunner: CommandRunning, @unchecked Sendable {
  struct Runners: Sendable {
    let application: ApplicationCommandRunner
    let builtIn: BuiltInCommandRunner
    let bundled: BundledCommandRunner
    let inputSource: InputSourceCommandRunner
    let keyboard: KeyboardCommandRunner
    let menubar: MenuBarCommandRunner
    let mouse: MouseCommandRunner
    let open: OpenCommandRunner
    let script: ScriptCommandRunner
    let shortcut: ShortcutsCommandRunner
    let system: SystemCommandRunner
    let text: TextCommandRunner
    let uiElement: UIElementCommandRunner
    let windowFocus: WindowCommandFocusRunner
    let windowManagement: WindowManagementCommandRunner
    let windowTiling: WindowTilingCommandRunner

    @MainActor
    func setMachPort(_ machPort: MachPortEventController?) {
      keyboard.machPort = machPort
      system.machPort = machPort
      uiElement.machPort = machPort
    }
  }

  private let applicationStore: ApplicationStore
  private let missionControl: MissionControlPlugin
  private let workspace: WorkspaceProviding
  private let commandPanel: CommandPanelCoordinator
  private var machPort: MachPortEventController?
  private var serialTask: Task<Void, Error>?
  private var concurrentTask: Task<Void, Error>?
  private var subscription: AnyCancellable?
  private var longRunningTask: Task<Void, any Error>?

  let runners: Runners

  @MainActor private var notchInfo: DynamicNotchInfo?
  @MainActor var lastExecutedCommand: Command?
  @MainActor var eventSource: CGEventSource?

  @MainActor
  init(_ workspace: WorkspaceProviding = NSWorkspace.shared,
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       applicationStore: ApplicationStore,
       builtInCommandRunner: BuiltInCommandRunner,
       scriptCommandRunner: ScriptCommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner,
       systemCommandRunner: SystemCommandRunner,
       uiElementCommandRunner: UIElementCommandRunner)
  {
    let windowTidy = WindowTidyRunner()

    self.applicationStore = applicationStore
    missionControl = MissionControlPlugin(keyboard: keyboardCommandRunner)
    commandPanel = CommandPanelCoordinator()

    let windowCenter = WindowFocusCenter()
    let relativeFocus = WindowFocusRelativeFocus()
    let quarterFocus = WindowFocusQuarter()
    let windowFocus = WindowCommandFocusRunner(centerFocus: windowCenter, relativeFocus: relativeFocus, quarterFocus: quarterFocus)

    runners = .init(
      application: ApplicationCommandRunner(
        applicationActivityMonitor: applicationActivityMonitor,
        scriptCommandRunner: scriptCommandRunner,
        keyboard: keyboardCommandRunner,
        workspace: workspace
      ),
      builtIn: builtInCommandRunner,
      bundled: BundledCommandRunner(applicationStore: applicationStore,
                                    windowFocusRunner: windowFocus,
                                    windowTidy: windowTidy),
      inputSource: InputSourceCommandRunner(),
      keyboard: keyboardCommandRunner,
      menubar: MenuBarCommandRunner(),
      mouse: MouseCommandRunner(),
      open: OpenCommandRunner(scriptCommandRunner, workspace: workspace),
      script: scriptCommandRunner,
      shortcut: ShortcutsCommandRunner(scriptCommandRunner),
      system: systemCommandRunner,
      text: TextCommandRunner(keyboardCommandRunner),
      uiElement: uiElementCommandRunner,
      windowFocus: windowFocus,
      windowManagement: WindowManagementCommandRunner(),
      windowTiling: WindowTilingCommandRunner(centerFocus: windowCenter, relativeFocus: relativeFocus, quarterFocus: quarterFocus)
    )
    self.workspace = workspace

    Task { MouseMonitor.shared.startMonitor() }
  }

  func reveal(_ commands: [Command]) {
    Task {
      await missionControl.dismissIfActive()
    }
    for command in commands {
      switch command {
      case let .application(applicationCommand):
        workspace.reveal(applicationCommand.application.path)
      case let .open(openCommand):
        workspace.reveal(openCommand.path)
      case let .script(scriptCommand):
        if case let .path(path) = scriptCommand.source {
          workspace.reveal(path)
        }
      case let .shortcut(shortcut):
        Task(priority: .userInitiated) {
          let source = """
          shortcuts view "\(shortcut.shortcutIdentifier)"
          """
          let shellScript = ScriptCommand(name: "Reveal \(shortcut.shortcutIdentifier)",
                                          kind: .shellScript, source: .inline(source), notification: nil)

          _ = try await runners.script.run(shellScript, snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false),
                                           runtimeDictionary: [:], checkCancellation: false)
        }
      case .builtIn, .keyboard, .text,
           .systemCommand, .menuBar, .windowManagement,
           .mouse, .uiElement, .bundled, .windowFocus, .windowTiling:
        break
      }
    }
  }

  @discardableResult
  func serialRun(_ commands: [Command], checkCancellation: Bool,
                 resolveUserEnvironment: Bool, machPortEvent: MachPortEvent,
                 repeatingEvent: Bool) -> Task<Void, any Error>
  {
    let originalPasteboardContents: String? = commands.shouldRestorePasteboard
      ? NSPasteboard.general.string(forType: .string)
      : nil

    if commands.shouldAutoCancelledPreviousCommands {
      concurrentTask?.cancel()
      serialTask?.cancel()
    }

    let serialTask = Task.detached(priority: .userInitiated) { [weak self] in
      Benchmark.shared.start("CommandRunner.serialRun")
      guard let self else { return }

      do {
        let shouldDismissMissionControl = commands.contains(where: {
          switch $0 {
          case .builtIn: false
          default: true
          }
        })

        if shouldDismissMissionControl { await missionControl.dismissIfActive() }
        var snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: resolveUserEnvironment)
        var runtimeDictionary = [String: String]()

        for command in commands {
          if checkCancellation { try Task.checkCancellation() }
          do {
            try await self.run(command, workflowCommands: commands, snapshot: &snapshot,
                               machPortEvent: machPortEvent,
                               checkCancellation: checkCancellation,
                               repeatingEvent: repeatingEvent, runtimeDictionary: &runtimeDictionary)
            if case .bundled = command {
              await runners.windowFocus.resetFocusComponents()
            }
          } catch let scriptError as ShellScriptPlugin.ShellScriptPluginError {
            await MainActor.run {
              let alert = NSAlert()
              switch scriptError {
              case .noData:
                alert.messageText = "No Data"
              case let .scriptError(string):
                alert.messageText = string
              }

              KeyboardCowboyApp.activate()

              CapsuleNotificationWindow.shared.publish(scriptError.localizedDescription, id: command.id, state: .failure)

              alert.runModal()
            }

            throw scriptError
          } catch {
            switch command.notification {
            case .bezel:
              await showFinishedNotification(for: command, output: error.localizedDescription)
            case .capsule:
              await CapsuleNotificationWindow.shared.publish(error.localizedDescription, id: command.id, state: .failure)
            case .commandPanel, .none: break
            }
          }
          if let delay = command.delay {
            try await Task.sleep(for: .milliseconds(delay))
          }
        }

        if commands.shouldRestorePasteboard {
          try await Task.sleep(for: .seconds(0.2))
          await MainActor.run { [originalPasteboardContents] in
            if let originalPasteboardContents {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(originalPasteboardContents, forType: .string)
            }
          }
        }
      }
      Benchmark.shared.stop("CommandRunner.serialRun")
    }

    self.serialTask = serialTask

    return serialTask
  }

  func concurrentRun(_ commands: [Command], checkCancellation: Bool,
                     resolveUserEnvironment: Bool, machPortEvent: MachPortEvent,
                     repeatingEvent: Bool)
  {
    var modifiedCheckCancellation = checkCancellation
    let originalPasteboardContents: String? = commands.shouldRestorePasteboard
      ? NSPasteboard.general.string(forType: .string)
      : nil
    if commands.count == 1 {
      modifiedCheckCancellation = false
    }

    if commands.shouldAutoCancelledPreviousCommands {
      serialTask?.cancel()
      concurrentTask?.cancel()
    }

    let checkCancellation = modifiedCheckCancellation
    concurrentTask?.cancel()
    concurrentTask = Task.detached(priority: .userInitiated) { [weak self, originalPasteboardContents] in
      guard let self else { return }

      let shouldDismissMissionControl = commands.contains(where: {
        switch $0 {
        case .builtIn: false default: true
        }
      })

      if shouldDismissMissionControl { await missionControl.dismissIfActive() }

      var snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: resolveUserEnvironment)
      var runtimeDictionary = [String: String]()
      for command in commands {
        do {
          if checkCancellation { try Task.checkCancellation() }
          try await self.run(command, workflowCommands: commands, snapshot: &snapshot,
                             machPortEvent: machPortEvent, checkCancellation: checkCancellation,
                             repeatingEvent: repeatingEvent, runtimeDictionary: &runtimeDictionary)
        } catch {
          switch command.notification {
          case .bezel:
            await showFinishedNotification(for: command, output: error.localizedDescription)
          case .capsule:
            await CapsuleNotificationWindow.shared.publish(error.localizedDescription, id: command.id, state: .failure)
          case .commandPanel, .none: break
          }
        }
      }

      if commands.shouldRestorePasteboard {
        try await Task.sleep(for: .seconds(0.2))
        await MainActor.run { [originalPasteboardContents] in
          if let originalPasteboardContents {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(originalPasteboardContents, forType: .string)
          }
        }
      }
    }
  }

  func run(_ command: Command, workflowCommands: [Command], snapshot: inout UserSpace.Snapshot,
           machPortEvent: MachPortEvent, checkCancellation: Bool, repeatingEvent: Bool,
           runtimeDictionary: inout [String: String]) async throws
  {
    await showRunningNotification(for: command)

    let output: String
    switch command {
    case let .application(applicationCommand):
      try await runners.application.run(applicationCommand, machPortEvent: machPortEvent,
                                        checkCancellation: checkCancellation, snapshot: &snapshot)
      output = command.name
    case let .builtIn(builtInCommand):
      output = try await runners.builtIn.run(
        builtInCommand,
        snapshot: snapshot,
        machPortEvent: machPortEvent
      )
    case let .bundled(bundledCommand):
      output = try await runners.bundled.run(
        bundledCommand: bundledCommand,
        command: command,
        commandRunner: self,
        snapshot: &snapshot,
        machPortEvent: machPortEvent,
        checkCancellation: checkCancellation,
        repeatingEvent: repeatingEvent,
        runtimeDictionary: &runtimeDictionary
      )
      snapshot = await snapshot.updateFrontmostApplication()
    case let .keyboard(command):
      switch command.kind {
      case let .key(keyboardCommand):
        try await runners.keyboard.run(
          keyboardCommand.keyboardShortcuts,
          originalEvent: nil,
          iterations: keyboardCommand.iterations,
          with: eventSource
        )
        try await Task.sleep(for: .milliseconds(1))
        output = command.name
      case let .inputSource(command):
        try await runners.inputSource.run(command)
        output = command.name
      }
    case let .menuBar(menuBarCommand):
      try await runners.menubar.execute(menuBarCommand, repeatingEvent: repeatingEvent)
      output = command.name
    case let .mouse(command):
      try await runners.mouse.run(command, snapshot: snapshot)
      output = command.name
    case let .open(openCommand):
      let path = await snapshot.interpolateUserSpaceVariables(openCommand.path, runtimeDictionary: runtimeDictionary)
      try await runners.open.run(path, checkCancellation: checkCancellation, application: openCommand.application)
      if !openCommand.name.isEmpty {
        output = openCommand.name
      } else {
        output = path
      }
    case let .script(scriptCommand):
      let result = try await runners.script.run(
        scriptCommand,
        snapshot: snapshot,
        runtimeDictionary: runtimeDictionary,
        checkCancellation: checkCancellation
      )

      output = if let result {
        scriptCommand.meta.variableName != nil
          ? result
          : command.name + " " + result.trimmingCharacters(in: .newlines)
      } else {
        command.name
      }
    case let .shortcut(shortcutCommand):
      let result = try await runners.shortcut.run(shortcutCommand,
                                                  environment: snapshot.terminalEnvironment(),
                                                  checkCancellation: checkCancellation)
      output = if let result {
        command.name + " " + result.trimmingCharacters(in: .newlines)
      } else {
        command.name
      }
    case let .text(typeCommand):
      switch typeCommand.kind {
      case let .insertText(typeCommand):
        try await runners.text.run(typeCommand, snapshot: snapshot, runtimeDictionary: runtimeDictionary)
        output = command.name
      }
    case let .systemCommand(systemCommand):
      try await runners.system.run(
        systemCommand,
        workflowCommands: workflowCommands,
        machPortEvent: machPortEvent,
        applicationRunner: runners.application,
        runtimeDictionary: runtimeDictionary,
        checkCancellation: checkCancellation, snapshot: snapshot
      )
      output = command.name
    case let .uiElement(uiElementCommand):
      try await runners.uiElement.run(uiElementCommand, checkCancellation: checkCancellation)
      output = ""
    case let .windowFocus(command):
      try await runners.windowFocus.run(command, snapshot: snapshot)
      snapshot = await snapshot.updateFrontmostApplication()
      output = ""
    case let .windowTiling(command):
      output = ""
      try await runners.windowTiling.run(command, snapshot: snapshot)
    case let .windowManagement(windowCommand):
      try await runners.windowManagement.run(windowCommand)

      if case let .moveToNextDisplay(mode) = windowCommand.kind,
         case .center = mode
      {
        let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
        Task.detached { [windowTiling = runners.windowTiling] in
          try await Task.sleep(for: .milliseconds(200))
          try await windowTiling.run(.init(kind: .center, meta: .init()), snapshot: snapshot)
        }
      }

      output = ""
    }

    if let variableName = command.meta.variableName {
      runtimeDictionary[variableName] = output
    }

    await showFinishedNotification(for: command, output: output)
  }

  @MainActor
  func setMachPort(_ machPort: MachPortEventController?, coordinator: MachPortCoordinator) {
    self.machPort = machPort
    runners.setMachPort(machPort)
    UserSpace.shared.machPort = machPort
    UserSpace.shared.subscribe(to: coordinator.$lastEventOrRebinding)
    subscribe(to: coordinator.$event)
    runners.windowManagement.subscribe(to: coordinator.$event)
  }

  // MARK: Private methods

  @MainActor
  private func setNotchInfo(_ notchInfo: DynamicNotchInfo?) {
    self.notchInfo = notchInfo
  }

  private func showRunningNotification(for command: Command) async {
    longRunningTask?.cancel()
    longRunningTask = nil

    switch command.notification {
    case .bezel:
      let notchInfo = await DynamicNotchInfo(
        icon: nil,
        title: LocalizedStringKey(stringLiteral: command.name),
        description: "Running…",
        style: NSScreen.main!.isMirrored() ? .floating(cornerRadius: 20) : .auto
      )
      await setNotchInfo(notchInfo)

      longRunningTask = Task.detached { [notchInfo] in
        await notchInfo.expand(on: NSScreen.main ?? NSScreen.screens[0])
        try await Task.sleep(for: .seconds(10))
      }
    case .capsule:
      longRunningTask = Task.detached {
        try await Task.sleep(for: .seconds(0.5))

        let capsule = await CapsuleNotificationWindow.shared

        await capsule.open()
        await capsule.publish("Running…", id: command.id, state: .running)
      }
    case .commandPanel:
      switch command {
      case let .script(scriptCommand):
        await MainActor.run {
          commandPanel.run(scriptCommand)
        }
      default:
        assertionFailure("Not yet implemented.")
      }
      return
    case .none:
      break
    }
  }

  private func showFinishedNotification(for command: Command, output: String) async {
    longRunningTask?.cancel()
    longRunningTask = nil

    switch command.notification {
    case .bezel:
      Task { @MainActor in
        lastExecutedCommand = command
        guard let notchInfo else { return }

        notchInfo.title = LocalizedStringKey(stringLiteral: output)
        notchInfo.description = nil
        await notchInfo.expand(on: NSScreen.main ?? NSScreen.screens[0])
        try await Task.sleep(for: .seconds(2))
        await notchInfo.hide()
        self.notchInfo = nil
      }
    case .capsule:
      Task.detached { @MainActor in
        let capsule = CapsuleNotificationWindow.shared
        if !capsule.isOpen { capsule.open() }
        capsule.publish(output, id: command.id, state: .success)
      }
    case .commandPanel:
      break // Add support for command windows
    case .none:
      break
    }
  }

  private func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    subscription = publisher
      .compactMap { $0 }
      .sink { [weak self] machPortEvent in
        let emptyFlags = machPortEvent.event.flags == CGEventFlags.maskNonCoalesced

        guard machPortEvent.keyCode == kVK_Escape,
              machPortEvent.type == .keyDown,
              emptyFlags
        else {
          return
        }

        self?.concurrentTask?.cancel()
        self?.serialTask?.cancel()
      }
  }
}

extension Collection where Element == Command {
  var shouldAutoCancelledPreviousCommands: Bool {
    contains(where: { command in
      switch command {
      case let .bundled(bundledCommand):
        switch bundledCommand.kind {
        case .assignToWorkspace, .moveToWorkspace: return false
        case .activatePreviousWorkspace, .appFocus, .workspace, .tidy:
          return true
        }
      default:
        return false
      }
    })
  }

  var shouldRestorePasteboard: Bool {
    contains(where: { command in
      if case let .text(textCommand) = command,
         case let .insertText(typeCommand) = textCommand.kind
      {
        switch typeCommand.mode {
        case .instant:
          return true
        case .typing:
          return false
        }
      } else {
        return false
      }
    })
  }
}

extension CGEventSource: @unchecked @retroactive Sendable { }
