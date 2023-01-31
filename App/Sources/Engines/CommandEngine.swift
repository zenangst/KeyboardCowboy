import Foundation
import AppKit
import MachPort

final class CommandEngine {
  struct Engines {
    let application: ApplicationEngine
    let keyboard: KeyboardEngine
    let open: OpenEngine
    let script: ScriptEngine
    let shortcut: ShortcutsEngine
    let type: TypeEngine
  }

  var machPort: MachPortEventController? {
    didSet {
      engines.keyboard.machPort = machPort
    }
  }

  private let engines: Engines
  private let workspace: WorkspaceProviding
  private var runningTask: Task<Void, Error>?

  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding,
       scriptEngine: ScriptEngine,
       keyCodeStore: KeyCodesStore) {
    let keyboard = KeyboardEngine(store: keyCodeStore)
    self.engines = .init(
      application: ApplicationEngine(
        scriptEngine: scriptEngine,
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      keyboard: keyboard,
      open: OpenEngine(scriptEngine, workspace: workspace),
      script: scriptEngine,
      shortcut: ShortcutsEngine(engine: scriptEngine),
      type: TypeEngine(keyboardEngine: keyboard, store: keyCodeStore)
    )
    self.workspace = workspace
  }

  func reveal(_ commands: [Command]) {
    for command in commands {
      switch command {
      case .application(let applicationCommand):
        workspace.reveal(applicationCommand.application.path)
      case .open(let openCommand):
        workspace.reveal(openCommand.path)
      case .script(let scriptCommand):
        switch scriptCommand {
        case .appleScript(_, _, _, let source),
            .shell(_, _, _, let source):
          switch source {
          case .path(let path):
            workspace.reveal(path)
          case .inline:
            // TODO: Open editing for this particular script.
            break
          }
        }
      case .shortcut(let shortcut):
        Task {
          let source = """
          shortcuts view "\(shortcut.shortcutIdentifier)"
          """
          _ = try await engines.script.run(.shell(id: UUID().uuidString, isEnabled: true,
                                                  name: "Reveal \(shortcut.shortcutIdentifier)",
                                                  source: .inline(source)))
        }
      case .builtIn(_):
        break
      case .keyboard(_):
        break
      case .type(_):
        break
      }
    }
  }

  func serialRun(_ commands: [Command]) {
    runningTask?.cancel()
    runningTask = Task.detached { [weak self] in
      guard let self = self else { return }
      do {
        for command in commands {
          try Task.checkCancellation()
          try await self.run(command)
        }
      }
    }
  }

  func concurrentRun(_ commands: [Command]) {
    for command in commands {
      Task {
        do {
          try await run(command)
        } catch { }
      }
    }
  }

  private func run(_ command: Command) async throws {
    switch command {
    case .application(let applicationCommand):
      try await engines.application.run(applicationCommand)
    case .builtIn(let builtInCommand):
      switch builtInCommand.kind {
      case .quickRun:
        break
      case .recordSequence:
        break
      case .repeatLastKeystroke:
        break
      }
    case .keyboard(let keyboardCommand):
      try engines.keyboard.run(keyboardCommand,
                               type: .keyDown,
                               originalEvent: nil,
                               with: eventSource)
    case .open(let openCommand):
      try await engines.open.run(openCommand)
    case .script(let scriptCommand):
      Task.detached {
        _ = try await self.engines.script.run(scriptCommand)
      }
    case .shortcut(let shortcutCommand):
      try await engines.shortcut.run(shortcutCommand)
    case .type(let typeCommand):
      try await engines.type.run(typeCommand)
    }
  }
}
