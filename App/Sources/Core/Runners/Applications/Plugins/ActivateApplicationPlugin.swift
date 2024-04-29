import Carbon
import Cocoa
import KeyCodes

final class ActivateApplicationPlugin {
  enum ActivateApplicationPlugin: Error {
    case failedToFindRunningApplication
    case failedToActivate
  }

  private let userSpace: UserSpace

  @MainActor
  init(userSpace: UserSpace = .shared) {
    self.userSpace = userSpace
  }

  /// Activate an application using its bundle identifier.
  ///
  /// Activation is done by filtering an match inside `UserSpace`'s `.runningApplications`.
  /// The first element that matches the bundle identifier will be used to activate the
  /// application by simply calling `activate` on the `NSRunningApplication`.
  /// `activate` is called with the options `.activateIgnoringOtherApps`
  ///
  /// - Parameter command: An application command which is used to resolve the applications
  ///                      bundle identifier.
  /// - Throws: If the method cannot match a running application then
  ///           a `.failedToFindRunningApplication` will be thrown.
  ///           If `.activate` should fail, then another error will be thrown: `.failedToActivate`
  func execute(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    guard
      let runningApplication = userSpace
        .runningApplications
        .first(where:
                { $0.bundleIdentifier.lowercased() == command.application.bundleIdentifier.lowercased() }
        ) else {
      throw ActivateApplicationPlugin.failedToFindRunningApplication
    }

    var options: NSApplication.ActivationOptions = .activateIgnoringOtherApps

    if userSpace.frontMostApplication.bundleIdentifier.lowercased() == command.application.bundleIdentifier.lowercased() {
      options.insert(.activateAllWindows)
    }

    if checkCancellation { try Task.checkCancellation() }

    if !runningApplication.ref.activate(options: options) {
      throw ActivateApplicationPlugin.failedToActivate
    }
  }
}
