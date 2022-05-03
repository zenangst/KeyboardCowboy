import Foundation
import AppKit

final class CommandEngine {
  struct Engines {
    let application: ApplicationCommandEngine
    let keyboard: KeyboardEngine
    let open: OpenCommandEngine
    let script: ScriptCommandEngine
    let shortcut: ShortcutCommandEngine
  }

  private let engines: Engines
  private let workspace: WorkspaceProviding

  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding, keyCodeStore: KeyCodeStore) {
    let script = ScriptCommandEngine()
    self.engines = .init(
      application: ApplicationCommandEngine(
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      keyboard: KeyboardEngine(store: keyCodeStore),
      open: OpenCommandEngine(workspace),
      script: script,
      shortcut: ShortcutCommandEngine(script: script)
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
    Task {
      do {
        for command in commands {
          try await run(command)
        }
      } catch { }
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
      try engines.keyboard.run(keyboardCommand, type: .keyDown, with: eventSource)
    case .open(let openCommand):
      try await engines.open.run(openCommand)
    case .script(let scriptCommand):
      _ = try await engines.script.run(scriptCommand)
    case .shortcut(let shortcutCommand):
      try await engines.shortcut.run(shortcutCommand)
    case .type:
      // TODO: Implement typing commands.
      break
    }
  }
}
