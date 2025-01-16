import AppKit
import Carbon
import Combine
import DynamicNotchKit
import Foundation
import MachPort
import SwiftUI

protocol CommandRunning {
  func serialRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool,
                 machPortEvent: MachPortEvent, repeatingEvent: Bool)
  func concurrentRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool,
                     machPortEvent: MachPortEvent, repeatingEvent: Bool)
}

final class CommandRunner: CommandRunning, @unchecked Sendable {
  struct Runners {
    let application: ApplicationCommandRunner
    let builtIn: BuiltInCommandRunner
    let bundled: BundledCommandRunner
    let keyboard: KeyboardCommandRunner
    let menubar: MenuBarCommandRunner
    let mouse: MouseCommandRunner
    let open: OpenCommandRunner
    let script: ScriptCommandRunner
    let shortcut: ShortcutsCommandRunner
    let system: SystemCommandRunner
    let text: TextCommandRunner
    let uiElement: UIElementCommandRunner
    let window: WindowCommandRunner

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

  let runners: Runners

  private var notchInfo: DynamicNotchInfo = DynamicNotchInfo(title: "")

  @MainActor
  var lastExecutedCommand: Command?
  var eventSource: CGEventSource?

  @MainActor
  init(_ workspace: WorkspaceProviding = NSWorkspace.shared,
       applicationStore: ApplicationStore,
       builtInCommandRunner: BuiltInCommandRunner,
       scriptCommandRunner: ScriptCommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner,
       systemCommandRunner: SystemCommandRunner,
       uiElementCommandRunner: UIElementCommandRunner
  ) {
    let windowTidy = WindowTidyRunner()

    self.applicationStore = applicationStore
    self.missionControl = MissionControlPlugin(keyboard: keyboardCommandRunner)
    self.commandPanel = CommandPanelCoordinator()
    self.runners = .init(
      application: ApplicationCommandRunner(
        scriptCommandRunner: scriptCommandRunner,
        keyboard: keyboardCommandRunner,
        workspace: workspace
      ),
      builtIn: builtInCommandRunner,
      bundled: BundledCommandRunner(applicationStore: applicationStore, systemRunner: systemCommandRunner, windowTidy: windowTidy),
      keyboard: keyboardCommandRunner,
      menubar: MenuBarCommandRunner(),
      mouse: MouseCommandRunner(),
      open: OpenCommandRunner(scriptCommandRunner, workspace: workspace),
      script: scriptCommandRunner,
      shortcut: ShortcutsCommandRunner(scriptCommandRunner),
      system: systemCommandRunner,
      text: TextCommandRunner(keyboardCommandRunner),
      uiElement: uiElementCommandRunner,
      window: WindowCommandRunner()
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
      case .application(let applicationCommand):
        workspace.reveal(applicationCommand.application.path)
      case .open(let openCommand):
        workspace.reveal(openCommand.path)
      case .script(let scriptCommand):
        if case .path(let path) = scriptCommand.source {
          workspace.reveal(path)
        }
      case .shortcut(let shortcut):
        Task(priority: .userInitiated) {
          let source = """
          shortcuts view "\(shortcut.shortcutIdentifier)"
          """
          let shellScript = ScriptCommand(name: "Reveal \(shortcut.shortcutIdentifier)",
                                          kind: .shellScript, source: .inline(source), notification: nil)

          _ = try await runners.script.run(shellScript, environment: [:], checkCancellation: false)
        }
      case .builtIn, .keyboard, .text,
          .systemCommand, .menuBar, .windowManagement, 
          .mouse, .uiElement, .bundled:
        break
      }
    }
  }

  func serialRun(_ commands: [Command], checkCancellation: Bool,
                 resolveUserEnvironment: Bool, machPortEvent: MachPortEvent,
                 repeatingEvent: Bool) {
    let originalPasteboardContents: String? = commands.shouldRestorePasteboard
    ? NSPasteboard.general.string(forType: .string)
    : nil

    if commands.shouldAutoCancelledPreviousCommands {
      concurrentTask?.cancel()
      serialTask?.cancel()
    }

    serialTask = Task.detached(priority: .userInitiated) { [weak self] in
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
        let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: resolveUserEnvironment)
        var runtimeDictionary = [String: String]()

        for command in commands {
          if checkCancellation { try Task.checkCancellation() }
          do {
            try await self.run(command, workflowCommands: commands, snapshot: snapshot,
                               machPortEvent: machPortEvent,
                               checkCancellation: checkCancellation,
                               repeatingEvent: repeatingEvent, runtimeDictionary: &runtimeDictionary)
          } catch { 
            if case .bezel = command.notification {
              await BezelNotificationController.shared.post(.init(id: UUID().uuidString, text: ""))
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
  }

  func concurrentRun(_ commands: [Command], checkCancellation: Bool,
                     resolveUserEnvironment: Bool, machPortEvent: MachPortEvent,
                     repeatingEvent: Bool) {
    var modifiedCheckCancellation = checkCancellation
    let originalPasteboardContents: String? = commands.shouldRestorePasteboard
                                            ? NSPasteboard.general.string(forType: .string)
                                            : nil

    if commands.filter({ $0.isEnabled }).count == 1 {
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

      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: resolveUserEnvironment)
      var runtimeDictionary = [String: String]()
      for command in commands {
        do {
          if checkCancellation { try Task.checkCancellation() }
          try await self.run(command, workflowCommands: commands, snapshot: snapshot,
                             machPortEvent: machPortEvent, checkCancellation: checkCancellation,
                             repeatingEvent: repeatingEvent, runtimeDictionary: &runtimeDictionary)
        } catch { 
          if case .bezel = command.notification {
            await BezelNotificationController.shared.post(.init(id: UUID().uuidString, text: ""))
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

  func run(_ command: Command, workflowCommands: [Command], snapshot: UserSpace.Snapshot,
           machPortEvent: MachPortEvent, checkCancellation: Bool, repeatingEvent: Bool,
           runtimeDictionary: inout [String: String]) async throws {
    let contentID = UUID()
    switch command.notification {
    case .bezel:
      await MainActor.run {
        notchInfo.setContent(contentID: contentID, title: command.name, description: "Running...")
        notchInfo.show(on: NSScreen.main ?? NSScreen.screens[0], for: 10.0)
      }
    case .commandPanel:
      switch command {
      case .script(let scriptCommand):
        await MainActor.run {
          commandPanel.run(scriptCommand)
        }
      default:
        assertionFailure("Not yet implemented.")
        break
      }
      return
    case .none:
      break
    }

    let output: String
    switch command {
    case .application(let applicationCommand):
      try await runners.application.run(applicationCommand, machPortEvent: machPortEvent,
                                        checkCancellation: checkCancellation)
      output = command.name
    case .builtIn(let builtInCommand):
      output = try await runners.builtIn.run(
        builtInCommand,
        snapshot: snapshot,
        machPortEvent: machPortEvent
      )
    case .bundled(let bundledCommand):
      output = try await runners.bundled.run(
        bundledCommand: bundledCommand,
        command: command,
        commandRunner: self,
        snapshot: snapshot,
        machPortEvent: machPortEvent,
        checkCancellation: checkCancellation,
        repeatingEvent: repeatingEvent,
        runtimeDictionary: &runtimeDictionary
      )
    case .keyboard(let keyboardCommand):
      try await runners.keyboard.run(
        keyboardCommand.keyboardShortcuts,
        originalEvent: nil,
        iterations: keyboardCommand.iterations,
        with: eventSource
      )
      try await Task.sleep(for: .milliseconds(1))
      output = command.name
    case .menuBar(let menuBarCommand):
      try await runners.menubar.execute(menuBarCommand, repeatingEvent: repeatingEvent)
      output = command.name
    case .mouse(let command):
      try await runners.mouse.run(command, snapshot: snapshot)
      output = command.name
    case .open(let openCommand):
      let path = await snapshot.interpolateUserSpaceVariables(openCommand.path, runtimeDictionary: runtimeDictionary)
      try await runners.open.run(path, checkCancellation: checkCancellation, application: openCommand.application)
      output = path
    case .script(let scriptCommand):
      let result = try await self.runners.script.run(
        scriptCommand,
        environment: snapshot.terminalEnvironment(),
        checkCancellation: checkCancellation
      )

      if let result = result {
        if scriptCommand.meta.variableName != nil {
          output = result
        } else {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        }
      } else {
        output = command.name
      }
    case .shortcut(let shortcutCommand):
      let result = try await runners.shortcut.run(shortcutCommand, 
                                                  environment: snapshot.terminalEnvironment(),
                                                  checkCancellation: checkCancellation)
      if let result = result {
        let trimmedResult = result.trimmingCharacters(in: .newlines)
        output = command.name + " " + trimmedResult
      } else {
        output = command.name
      }
    case .text(let typeCommand):
      switch typeCommand.kind {
      case .insertText(let typeCommand):
        try await runners.text.run(typeCommand, snapshot: snapshot, runtimeDictionary: runtimeDictionary)
        output = command.name
      }
    case .systemCommand(let systemCommand):
      try await runners.system.run(
        systemCommand,
        workflowCommands: workflowCommands,
        applicationRunner: runners.application,
        runtimeDictionary: runtimeDictionary,
        checkCancellation: checkCancellation, snapshot: snapshot
      )
      output = command.name
    case .uiElement(let uiElementCommand):
      try await runners.uiElement.run(uiElementCommand, checkCancellation: checkCancellation)
      output = ""
    case .windowManagement(let windowCommand):
      try await runners.window.run(windowCommand)

      if case .moveToNextDisplay(let mode) = windowCommand.kind,
         case .center = mode {
        let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
        Task.detached {
          try await Task.sleep(for: .milliseconds(200))
          try await SystemWindowTilingRunner.run(.center, snapshot: snapshot)
        }
      }

      output = ""
    }

    if let variableName = command.meta.variableName {
      runtimeDictionary[variableName] = output
    }

    switch command.notification {
    case .bezel:
      await MainActor.run {
        lastExecutedCommand = command
        notchInfo.setContent(contentID: contentID, title: output, description: nil)
        notchInfo.show(on: NSScreen.main ?? NSScreen.screens[0], for: 2.0)
      }
    case .commandPanel:
      break // Add support for command windows
    case .none:
      break
    }
  }

  @MainActor
  func setMachPort(_ machPort: MachPortEventController?, coordinator: MachPortCoordinator) {
    self.machPort = machPort
    runners.setMachPort(machPort)
    UserSpace.shared.machPort = machPort
    UserSpace.shared.subscribe(to: coordinator.$lastEventOrRebinding)
    WindowStore.shared.subscribe(to: coordinator.$flagsChanged)
    subscribe(to: coordinator.$event)
    runners.system.subscribe(to: coordinator.$flagsChanged)
    runners.window.subscribe(to: coordinator.$event)
  }

  // MARK: Private methods

  private func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    subscription = publisher
      .compactMap { $0 }
      .sink { [weak self] machPortEvent in
        let emptyFlags = machPortEvent.event.flags == CGEventFlags.maskNonCoalesced

        guard machPortEvent.keyCode == kVK_Escape,
              machPortEvent.type == .keyDown,
              emptyFlags else {
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
      case .bundled(let bundledCommand):
        switch bundledCommand.kind {
        case .appFocus, .workspace, .tidy:
          return true
        }
      default:
        return false
      }
    })
  }

  var shouldRestorePasteboard: Bool {
    contains(where: { command in
      if case .text(let textCommand) = command,
         case .insertText(let typeCommand) = textCommand.kind {
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
