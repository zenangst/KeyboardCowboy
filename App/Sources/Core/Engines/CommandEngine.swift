import Foundation
import AppKit
import MachPort

protocol CommandRunning {
  func serialRun(_ commands: [Command])
  func concurrentRun(_ commands: [Command])
}

final class CommandEngine: CommandRunning {
  struct Engines {
    let application: ApplicationEngine
    let keyboard: KeyboardEngine
    let menubar: MenuBarEngine
    let open: OpenEngine
    let script: ScriptEngine
    let shortcut: ShortcutsEngine
    let system: SystemCommandEngine
    let type: TypeEngine
  }

  var machPort: MachPortEventController? {
    didSet {
      engines.keyboard.machPort = machPort
      if let machPort {
        engines.system.machPort = machPort
        engines.system.subscribe(to: machPort.$flagsChanged)
      }
    }
  }

  private let missionControl: MissionControlPlugin
  private let workspace: WorkspaceProviding
  private var runningTask: Task<Void, Error>?
  
  let engines: Engines

  @MainActor
  var lastExecutedCommand: Command?
  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding,
       applicationStore: ApplicationStore,
       scriptEngine: ScriptEngine,
       keyboardEngine: KeyboardEngine) {
    let systemCommandEngine = SystemCommandEngine(applicationStore)
    self.missionControl = MissionControlPlugin(keyboard: keyboardEngine)
    self.engines = .init(
      application: ApplicationEngine(
        scriptEngine: scriptEngine,
        keyboard: keyboardEngine,
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      keyboard: keyboardEngine,
      menubar: MenuBarEngine(),
      open: OpenEngine(scriptEngine, workspace: workspace),
      script: scriptEngine,
      shortcut: ShortcutsEngine(engine: scriptEngine),
      system: systemCommandEngine,
      type: TypeEngine(keyboardEngine: keyboardEngine)
    )
    self.workspace = workspace
  }

  func reveal(_ commands: [Command]) {
    missionControl.dismissIfActive()
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

          _ = try await engines.script.run(shellScript)
        }
      case .builtIn, .keyboard, .type,
           .systemCommand, .menuBar:
        break
      }
    }
  }

  func serialRun(_ commands: [Command]) {
    missionControl.dismissIfActive()
    runningTask?.cancel()
    runningTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      do {
        for command in commands {
          try Task.checkCancellation()
          do {
            try await self.run(command)
          } catch { }
          if let delay = command.delay {
            try await Task.sleep(for: .milliseconds(delay))
          }
        }
      }
    }
  }

  func concurrentRun(_ commands: [Command]) {
    missionControl.dismissIfActive()
    runningTask?.cancel()
    runningTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      for command in commands {
        do {
          try Task.checkCancellation()
          try await self.run(command)
        } catch { }
      }
    }
  }

  func run(_ command: Command) async throws {
    do {
      let output: String
      switch command {
      case .application(let applicationCommand):
        try await engines.application.run(applicationCommand)
        output = command.name
      case .builtIn(let builtInCommand):
        switch builtInCommand.kind {
        case .quickRun:
          break
        case .recordSequence:
          break
        case .repeatLastKeystroke:
          break
        }
        output = command.name
      case .keyboard(let keyboardCommand):
        try engines.keyboard.run(keyboardCommand,
                                 type: .keyDown,
                                 originalEvent: nil,
                                 with: eventSource)
        try engines.keyboard.run(keyboardCommand,
                                 type: .keyUp,
                                 originalEvent: nil,
                                 with: eventSource)
        try await Task.sleep(for: .milliseconds(1))
        output = command.name
      case .menuBar(let menuBarCommand):
        try await engines.menubar.execute(menuBarCommand)
        output = command.name
      case .open(let openCommand):
        try await engines.open.run(openCommand)
        output = command.name
      case .script(let scriptCommand):
        let result = try await self.engines.script.run(scriptCommand)
        if let result = result {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        } else {
          output = command.name
        }
      case .shortcut(let shortcutCommand):
        try await engines.shortcut.run(shortcutCommand)
        output = command.name
      case .type(let typeCommand):
        try await engines.type.run(typeCommand)
        output = command.name
      case .systemCommand(let systemCommand):
        try await engines.system.run(systemCommand)
        output = command.name
      }

      if command.notification {
        await MainActor.run {
          lastExecutedCommand = command
          BezelNotificationController.shared.post(.init(text: output))
        }
      }
    } catch {
      throw error
    }
  }
}
