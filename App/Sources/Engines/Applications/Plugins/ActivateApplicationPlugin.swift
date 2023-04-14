import Carbon
import Cocoa
import KeyCodes

final class ActivateApplicationPlugin {
  enum ActivateApplicationPlugin: Error {
    case failedToFindRunningApplication
    case failedToActivate
  }

  private let workspace: WorkspaceProviding
  private let keyboard: KeyboardEngine

  init(keyboard: KeyboardEngine, workspace: WorkspaceProviding) {
    self.keyboard = keyboard
    self.workspace = workspace
  }

  /// Activate an application using its bundle identifier.
  ///
  /// Activation is done by filtering an match inside `NSWorkspace`'s `.runningApplications`.
  /// The first element that matches the bundle identifier will be used to activate the
  /// application by simply calling `activate` on the `NSRunningApplication`.
  /// `activate` is called with the options `.activateIgnoringOtherApps`
  ///
  /// - Parameter command: An application command which is used to resolve the applications
  ///                      bundle identifier.
  /// - Throws: If the method cannot match a running application then
  ///           a `.failedToFindRunningApplication` will be thrown.
  ///           If `.activate` should fail, then another error will be thrown: `.failedToActivate`
  func execute(_ command: ApplicationCommand) async throws {
    guard
      let runningApplication = workspace
        .applications
        .first(where:
                { $0.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() }
        ) else {
      throw ActivateApplicationPlugin.failedToFindRunningApplication
    }

    var options: NSApplication.ActivationOptions = .activateIgnoringOtherApps

    if workspace.frontApplication?.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() {
      options.insert(.activateAllWindows)
    }

    try Task.checkCancellation()

    if !runningApplication.activate(options: options) {
      throw ActivateApplicationPlugin.failedToActivate
    }

    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as [AnyObject]? ?? []
    let missionControlIsActive = !windows.filter { entry in
      guard let appName = entry[kCGWindowOwnerName as String] as? String,
            let layer = entry[kCGWindowLayer as String] as? Int,
            appName == "Dock" &&
            layer == CGWindowLevelKey.desktopIconWindow.rawValue else {
        return false
      }

      return true
    }.isEmpty

    if missionControlIsActive {
      
    }
  }
}
