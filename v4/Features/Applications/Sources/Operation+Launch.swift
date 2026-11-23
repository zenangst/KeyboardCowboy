import Apps
import Cocoa
import Commands
import Foundation
import RuntimeEnvironment

extension Operation {
  final class Launch: Sendable {
    let env: RuntimeEnvironment.Mode
    let workspace: Application.Workspace

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
      self.workspace = Application.Workspace(env)
    }

    func callAsFunction(at path: String, with modifiers: Set<Command.Application.Modifier>) async throws {
      try Task.checkCancellation()
      let configuration = NSWorkspace.OpenConfiguration(modifiers)
      let applicationURL = URL(fileURLWithPath: path)

      do {
        try await workspace.openApplication(
          at: applicationURL,
          configuration: configuration,
        )
      } catch {
        try Task.checkCancellation()
        throw error
      }
      try Task.checkCancellation()
    }
  }
}
