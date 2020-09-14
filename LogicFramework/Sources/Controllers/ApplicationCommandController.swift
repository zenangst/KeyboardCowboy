import Cocoa
import Combine

public protocol ApplicationCommandControlling: CommandPublishing {
  /// Run `ApplicationCommand` which should either launch or
  /// activate the target application. The `Application` struct
  /// is used to determine which app should be invoked.
  ///
  /// - Parameter command: An `ApplicationCommand` that indicates
  ///                      which application should be launched
  ///                      or activated if already running.
  func run(_ command: ApplicationCommand)
}

public enum ApplicationCommandControllingError: Error {
  case failedToLaunch(ApplicationCommand)
  case failedToFindRunningApplication(ApplicationCommand)
  case failedToActivate(ApplicationCommand)
}

class ApplicationCommandController: ApplicationCommandControlling {
  internal let subject = PassthroughSubject<Command, Error>()
  let windowListProvider: WindowListProviding
  let workspace: WorkspaceProviding

  init(windowListProvider: WindowListProviding, workspace: WorkspaceProviding) {
    self.windowListProvider = windowListProvider
    self.workspace = workspace
  }

  // MARK: Public methods

  func run(_ command: ApplicationCommand) {
    // Verify if the current application has any open windows
    if windowListProvider.windowOwners().contains(command.application.bundleName) {
      activateApplication(command)
    } else {
      launchApplication(command)
    }
  }

  /// Launch an application using the applications bundle identifier
  /// Applications are launched using `NSWorkspace`
  ///
  /// - Parameter command: An application command which is used to resolve the applications
  ///                      bundle identifier.
  /// - Throws: If `NSWorkspace.launchApplication` returns `false`, the method will throw
  ///           `ApplicationCommandControllingError.failedToLaunch`
  private func launchApplication(_ command: ApplicationCommand) {
    if !workspace.launchApplication(withBundleIdentifier: command.application.bundleIdentifier,
                                    options: .default,
                                    additionalEventParamDescriptor: nil,
                                    launchIdentifier: nil) {
      let error = ApplicationCommandControllingError.failedToLaunch(command)
      subject.send(completion: .failure(error))
    } else {
      subject.send(completion: .finished)
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
  private func activateApplication(_ command: ApplicationCommand) {
    guard let runningApplication = workspace.applications
            .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }) else {
      subject.send(completion: .failure(ApplicationCommandControllingError.failedToFindRunningApplication(command)))
      return
    }

    if !runningApplication.activate(options: .activateIgnoringOtherApps) {
      subject.send(completion: .failure(ApplicationCommandControllingError.failedToActivate(command)))
    } else {
      subject.send(completion: .finished)
    }
  }
}
