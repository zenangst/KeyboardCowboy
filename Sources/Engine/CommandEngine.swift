import Foundation
import AppKit

final class CommandEngine {
  struct Engines {
    let application: ApplicationCommandEngine
  }

  let engines: Engines

  init(_ workspace: WorkspaceProviding) {
    self.engines = .init(application: ApplicationCommandEngine(
      windowListProvider: WindowListProvider(),
      workspace: NSWorkspace.shared
    ))
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
    case .open:
      break
    case .script:
      break
    case .type:
      break
    }
  }
}
