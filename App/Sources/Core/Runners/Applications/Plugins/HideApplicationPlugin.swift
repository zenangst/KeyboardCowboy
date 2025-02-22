import Apps
import Cocoa

final class HideApplicationPlugin {
  let workspace: WorkspaceProviding
  let userSpace: UserSpace

  @MainActor
  init(workspace: WorkspaceProviding = NSWorkspace.shared, userSpace: UserSpace = .shared) {
    self.workspace = workspace
    self.userSpace = userSpace
  }

  func execute(_ command: ApplicationCommand, snapshot: UserSpace.Snapshot) {
    if command.application.bundleIdentifier == Application.previousAppBundleIdentifier() {
      if !snapshot.previousApplication.ref.isHidden {
        _ = snapshot.previousApplication.ref.hide()
      }
      return
    }

    guard let runningApplication = workspace
      .applications
      .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }),
          !runningApplication.isHidden else {
      return
    }

    if workspace.frontApplication?.bundleIdentifier != command.application.bundleIdentifier {
      userSpace.frontmostApplication.ref.activate(options: .activateIgnoringOtherApps)
    }

    _ = runningApplication.hide()
  }
}
