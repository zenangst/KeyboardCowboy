import Foundation
import AppKit
import Carbon
import Combine
import MachPort

protocol CommandRunning {
  func serialRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool)
  func concurrentRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool)
}

final class CommandRunner: CommandRunning, @unchecked Sendable {
  struct Runners {
    let application: ApplicationCommandRunner
    let builtIn: BuiltInCommandRunner
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

  private let missionControl: MissionControlPlugin
  private let workspace: WorkspaceProviding
  private var machPort: MachPortEventController?
  private var serialTask: Task<Void, Error>?
  private var concurrentTask: Task<Void, Error>?
  private var subscription: AnyCancellable?

  let runners: Runners

  @MainActor
  var lastExecutedCommand: Command?
  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding = NSWorkspace.shared,
       applicationStore: ApplicationStore,
       builtInCommandRunner: BuiltInCommandRunner,
       scriptCommandRunner: ScriptCommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner,
       uiElementCommandRunner: UIElementCommandRunner
  ) {
    let systemCommandRunner = SystemCommandRunner(applicationStore)
    self.missionControl = MissionControlPlugin(keyboard: keyboardCommandRunner)
    self.runners = .init(
      application: ApplicationCommandRunner(
        scriptCommandRunner: scriptCommandRunner,
        keyboard: keyboardCommandRunner,
        workspace: workspace
      ),
      builtIn: builtInCommandRunner,
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

    Task { await MouseMonitor.shared.startMonitor() }
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
                                          kind: .shellScript, source: .inline(source), notification: false)

          _ = try await runners.script.run(shellScript, environment: [:])
        }
      case .builtIn, .keyboard, .text,
          .systemCommand, .menuBar, .windowManagement, 
          .mouse, .uiElement:
        break
      }
    }
  }

  func serialRun(
    _ commands: [Command],
    checkCancellation: Bool,
    resolveUserEnvironment: Bool
  ) {
    serialTask?.cancel()
    serialTask = Task.detached(priority: .userInitiated) { [weak self] in
      await Benchmark.shared.start("CommandRunner.serialRun")
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
        for command in commands {
          if checkCancellation { try Task.checkCancellation() }
          do {
            try await self.run(command, snapshot: snapshot)
          } catch { }
          if let delay = command.delay {
            try await Task.sleep(for: .milliseconds(delay))
          }
        }
      }
      await Benchmark.shared.stop("CommandRunner.serialRun")
    }
  }

  func concurrentRun(_ commands: [Command], checkCancellation: Bool, resolveUserEnvironment: Bool
  ) {
    concurrentTask?.cancel()
    concurrentTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return
      }
      let shouldDismissMissionControl = commands.contains(where: {
        switch $0 {
        case .builtIn: false
        default: true
        }
      })

      if shouldDismissMissionControl { await missionControl.dismissIfActive() }

      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: resolveUserEnvironment)
      for command in commands {
        do {
          if checkCancellation { try Task.checkCancellation() }
          try await self.run(command, snapshot: snapshot)
        } catch { }
      }
    }
  }

  func run(_ command: Command, snapshot: UserSpace.Snapshot) async throws {
    do {
      let id = UUID().uuidString
      if command.notification {
        await BezelNotificationController.shared.post(
          .init(id: id, text: " ", running: true)
        )
      }
      let output: String
      switch command {
      case .application(let applicationCommand):
        try await runners.application.run(applicationCommand)
        output = command.name
      case .builtIn(let builtInCommand):
        output = try await runners.builtIn.run(builtInCommand)
      case .keyboard(let keyboardCommand):
        try runners.keyboard.run(keyboardCommand.keyboardShortcuts,
                                 type: .keyDown,
                                 originalEvent: nil,
                                 with: eventSource)
        try runners.keyboard.run(keyboardCommand.keyboardShortcuts,
                                 type: .keyUp,
                                 originalEvent: nil,
                                 with: eventSource)
        try await Task.sleep(for: .milliseconds(1))
        output = command.name
      case .menuBar(let menuBarCommand):
        try await runners.menubar.execute(menuBarCommand)
        output = command.name
      case .mouse(let command):
        try await runners.mouse.run(command, snapshot: snapshot)
        output = command.name
      case .open(let openCommand):
        let path = snapshot.interpolateUserSpaceVariables(openCommand.path)
        try await runners.open.run(path, application: openCommand.application)
        output = path
      case .script(let scriptCommand):
        let result = try await self.runners.script.run(
          scriptCommand,
          environment: snapshot.terminalEnvironment()
        )
        if let result = result {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        } else {
          output = command.name
        }
      case .shortcut(let shortcutCommand):
        let result = try await runners.shortcut.run(shortcutCommand)
        if let result = result {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        } else {
          output = command.name
        }
      case .text(let typeCommand):
        switch typeCommand.kind {
        case .insertText(let typeCommand):
          try await runners.text.run(
            snapshot.interpolateUserSpaceVariables(typeCommand.input),
            mode: typeCommand.mode
          )
          output = command.name
        }
      case .systemCommand(let systemCommand):
        try await runners.system.run(
          systemCommand,
          applicationRunner: runners.application,
          snapshot: snapshot
        )
        output = command.name
      case .uiElement(let uiElementCommand):
        try await runners.uiElement.run(uiElementCommand)
        output = ""
      case .windowManagement(let windowCommand):
        try await runners.window.run(windowCommand)
        output = ""
      }

      if command.notification {
        await MainActor.run {
          lastExecutedCommand = command
          BezelNotificationController.shared.post(.init(id: id, text: output))
        }
      }
    } catch {
      throw error
    }
  }

  @MainActor
  func setMachPort(_ machPort: MachPortEventController?, coordinator: MachPortCoordinator) {
    self.machPort = machPort
    runners.setMachPort(machPort)
    UserSpace.shared.machPort = machPort
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
