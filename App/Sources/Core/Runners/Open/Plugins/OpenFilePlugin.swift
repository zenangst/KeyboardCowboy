import Apps
import Cocoa

final class OpenFilePlugin: Sendable {
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func execute(_ path: String, application: Application?) async throws {
    let url = OpenURLParser().parse(path)
    let configuration = NSWorkspace.OpenConfiguration()

    if let application = application {
      let applicationUrl = URL(fileURLWithPath: application.path)
      _ = try await workspace.open([url], withApplicationAt: applicationUrl, configuration: configuration)
    } else {
      _ = try await workspace.open(url, configuration: configuration)
    }
  }
}
