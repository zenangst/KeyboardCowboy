import Cocoa

final class HideApplicationPlugin {
  let workspace: WorkspaceProviding
  let userSpace: UserSpace

  init(workspace: WorkspaceProviding = NSWorkspace.shared,
       userSpace: UserSpace = .shared) {
    self.workspace = workspace
    self.userSpace = userSpace
  }

  func execute(_ command: ApplicationCommand) {
    guard let runningApplication = workspace
      .applications
      .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }),
          !runningApplication.isHidden else {
      return
    }

    userSpace.frontMostApplication.ref.activate()
    _ = runningApplication.hide()

  }
}
