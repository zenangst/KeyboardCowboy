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
  let windowListProvider: WindowListProviding
  let workspace: WorkspaceProviding

  init(windowListProvider: WindowListProviding, workspace: WorkspaceProviding) {
    self.windowListProvider = windowListProvider
    self.workspace = workspace
  }

  // MARK: Public methods

  func run(_ command: ApplicationCommand) throws {
    // Verify if the current application has any open windows
    if windowListProvider.windowOwners().contains(command.application.bundleName) {
      try activateApplication(command)
    } else {
      try launchApplication(command)
    }
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
    guard let runningApplication = workspace.applications
            .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }) else {
      throw ApplicationCommandControllingError.failedToFindRunningApplication(command)
    }

    if !runningApplication.activate(options: .activateIgnoringOtherApps) {
      throw ApplicationCommandControllingError.failedToActivate(command)
    }
  }
}
