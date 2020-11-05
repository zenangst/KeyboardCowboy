import Cocoa
import Combine
import ModelKit

public protocol ApplicationCommandControlling {
  /// Run `ApplicationCommand` which should either launch or
  /// activate the target application. The `Application` struct
  /// is used to determine which app should be invoked.
  ///
  /// - Parameter command: An `ApplicationCommand` that indicates
  ///                      which application should be launched
  ///                      or activated if already running.
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ command: ApplicationCommand) -> CommandPublisher
}

public enum ApplicationCommandControllingError: Error {
  case failedToLaunch(ApplicationCommand)
  case failedToFindRunningApplication(ApplicationCommand)
  case failedToActivate(ApplicationCommand)
}

final class ApplicationCommandController: ApplicationCommandControlling {
  let windowListProvider: WindowListProviding
  let workspace: WorkspaceProviding

  init(windowListProvider: WindowListProviding, workspace: WorkspaceProviding) {
    self.windowListProvider = windowListProvider
    self.workspace = workspace
  }

  // MARK: Public methods

  func run(_ command: ApplicationCommand) -> CommandPublisher {
    let shouldActivate = ["com.apple.finder"]
    let frontMostBundle = workspace.frontApplication?.bundleIdentifier
    let needsLaunching = frontMostBundle == command.application.bundleIdentifier.lowercased()
      && shouldActivate.contains(command.application.bundleIdentifier)

    // Verify if the current application has any open windows
    do {
      if windowListProvider.windowOwners().contains(command.application.bundleName) ||
          !needsLaunching {
        try activateApplication(command)
      } else {
        try launchApplication(command)
      }

      return Result.success(()).publisher.eraseToAnyPublisher()
    } catch {
      return Fail(error: error).eraseToAnyPublisher()
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
    guard
      let runningApplication = workspace
        .applications
        .first(where:
                { $0.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() }
        ) else {
      throw ApplicationCommandControllingError.failedToFindRunningApplication(command)
    }

    var options: NSApplication.ActivationOptions = .activateIgnoringOtherApps

    if workspace.frontApplication?.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() {
      options.insert(.activateAllWindows)
    }

    if !runningApplication.activate(options: options) {
      throw ApplicationCommandControllingError.failedToActivate(command)
    }
  }
}
