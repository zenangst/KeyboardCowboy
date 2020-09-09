import Cocoa

public protocol ApplicationCommandControlling: AnyObject {
  func run(_ command: ApplicationCommand) throws
}

public enum ApplicationCommandControllingError: Error {
  case failedToLaunch(ApplicationCommand)
  case failedToFindRunningApplication(ApplicationCommand)
  case failedToActivate(ApplicationCommand)
}

class ApplicationCommandController: ApplicationCommandControlling {
  let workspace: NSWorkspace

  init(workspace: NSWorkspace = .shared) {
    self.workspace = workspace
  }

  // MARK: Public methods

  func run(_ command: ApplicationCommand) throws {
    if applicationHasWindows(command.application) {
      try activateApplication(command)
    } else {
      try launchApplication(command)
    }
  }

  // MARK: Private methods

  /// Verify if the current application has any open windows
  ///
  /// Check if the application has any windows by generating an collection of window owners
  /// using `CGWindowListCopyWindowInfo`.
  /// The collection is then match against the applications `bundleName`.
  ///
  /// - Parameter application: The application that the windows should belong to, the applications
  ///                          bundle name is used for matching.
  /// - Returns: Returns true if any windows belonging to the application
  private func applicationHasWindows(_ application: Application) -> Bool {
    let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    let windowOwners = info.filter {
      ($0[kCGWindowLayer as String] as? Int ?? 0) >= 0
    }.compactMap({ $0[kCGWindowOwnerName as String] as? String })
    // TODO: Verify that `application.name` is `bundleName` and not a localized version.
    //       Matching is done using `bundleName`.
    return windowOwners.contains(application.name)
  }

  /// Launch an application using the applications bundle identifier
  /// Applications are launched using `NSWorkspace`
  ///
  /// - Parameter command: An application command which is used to resolve the applications
  ///                      bundle identifier.
  /// - Throws: If `NSWorkspace.launchApplication` returns `false`, the method will throw
  ///           `ApplicationCommandControllingError.failedToLaunch`
  private func launchApplication(_ command: ApplicationCommand) throws {
    if !workspace.launchApplication(withBundleIdentifier: command.application.bundleIdentifier,
                                    options: .default,
                                    additionalEventParamDescriptor: nil,
                                    launchIdentifier: nil) {
      throw ApplicationCommandControllingError.failedToLaunch(command)
    }
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
  private func activateApplication(_ command: ApplicationCommand) throws {
    guard let runningApplication = workspace.runningApplications
            .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }) else {
      throw ApplicationCommandControllingError.failedToFindRunningApplication(command)
    }

    if !runningApplication.activate(options: .activateIgnoringOtherApps) {
      throw ApplicationCommandControllingError.failedToActivate(command)
    }
  }
}
