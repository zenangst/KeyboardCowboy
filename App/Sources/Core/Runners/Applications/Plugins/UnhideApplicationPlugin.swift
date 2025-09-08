import Cocoa

final class UnhideApplicationPlugin {
  let workspace: WorkspaceProviding
  let userSpace: UserSpace

  @MainActor
  init(workspace: WorkspaceProviding = NSWorkspace.shared, userSpace: UserSpace = .shared) {
    self.workspace = workspace
    self.userSpace = userSpace
  }

  func execute(_ command: ApplicationCommand) {
    guard let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: command.application.bundleIdentifier).first,
    runningApplication.isHidden else {
      return
    }

    guard workspace.frontApplication?.bundleIdentifier != command.application.bundleIdentifier else {
      return
    }

    _ = runningApplication.unhide()
  }
}
