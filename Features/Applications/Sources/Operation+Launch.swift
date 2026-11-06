import Apps
import Cocoa
import CowboyCore
import Foundation

extension Operation {
  final class Launch: Sendable {
    let env: Core.Environment
    let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
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
