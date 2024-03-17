import Cocoa

final class LaunchApplicationPlugin {
  private let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func execute(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = !command.modifiers.contains(.background)
    configuration.hides = command.modifiers.contains(.hidden)

    let url = URL(fileURLWithPath: command.application.path)
    if checkCancellation { try Task.checkCancellation() }
    do {
      _ = try await workspace.openApplication(at: url, configuration: configuration)
    } catch {
      throw error
    }
  }
}
