import Cocoa

final class CloseApplicationPlugin {
  enum CloseApplicationPluginError: Error {
    case unableToTermineApplication
  }

  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func execute(_ command: ApplicationCommand) throws {
    guard let runningApplication = workspace.applications.first(where: {
      command.application.bundleIdentifier == $0.bundleIdentifier
    }) else {
      return
    }

    if !runningApplication.terminate() {
      throw CloseApplicationPluginError.unableToTermineApplication
    }
  }
}
