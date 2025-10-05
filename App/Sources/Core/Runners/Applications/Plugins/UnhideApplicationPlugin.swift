import AXEssibility
import Cocoa

final class UnhideApplicationPlugin {
  static let debug: Bool = true
  let workspace: WorkspaceProviding
  let userSpace: UserSpace

  @MainActor
  init(workspace: WorkspaceProviding = NSWorkspace.shared, userSpace: UserSpace = .shared) {
    self.workspace = workspace
    self.userSpace = userSpace
  }

  func execute(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    guard workspace.frontApplication?.bundleIdentifier != command.application.bundleIdentifier else {
      return
    }
    guard let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: command.application.bundleIdentifier).first
    else {
      return
    }

    if checkCancellation {
      try Task.checkCancellation()
    }

    runningApplication.unhide()
  }
}
