import Cocoa

final class OpenFilePlugin {
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func execute(_ command: OpenCommand, url: URL) async throws {
    let configuration = NSWorkspace.OpenConfiguration()

    if let application = command.application {
      let applicationUrl = URL(fileURLWithPath: application.path)
      _ = try await workspace.open([url], withApplicationAt: applicationUrl, configuration: configuration)
    } else {
      _ = try await workspace.open(url, configuration: configuration)
    }
  }
}
