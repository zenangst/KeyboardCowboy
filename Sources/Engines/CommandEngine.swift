import Foundation
import AppKit

final class CommandEngine {
  struct Engines {
    let application: ApplicationCommandEngine
    let open: OpenCommandEngine
    let script: ScriptCommandEngine
  }

  private let engines: Engines
  private let workspace: WorkspaceProviding

  init(_ workspace: WorkspaceProviding) {
    self.engines = .init(
      application: ApplicationCommandEngine(
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      open: OpenCommandEngine(workspace),
      script: ScriptCommandEngine()
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
      default:
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
    case .builtIn:
      break
    case .keyboard:
      break
    case .open(let openCommand):
      try await engines.open.run(openCommand)
    case .script(let scriptCommand):
      try await engines.script.run(scriptCommand)
    case .type:
      break
    }
  }
}
