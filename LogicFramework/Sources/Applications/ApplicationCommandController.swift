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
  case failedToLaunch
  case failedToFindRunningApplication
  case failedToActivate
  case failedToClose
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
    Future { [weak self] promise in
      guard let self = self else { return }

      if command.modifiers.contains(.onlyIfNotRunning) {
        let bundleIdentifiers = self.workspace.applications.compactMap({ $0.bundleIdentifier })
        if bundleIdentifiers.contains(command.application.bundleIdentifier) {
          promise(.success(()))
          return
        }
      }

      switch command.action {
      case .open:
        self.openApplication(command: command, promise: promise)
      case .close:
        self.closeApplication(command: command, promise: promise)
      }

    }.eraseToAnyPublisher()
  }

  private func openApplication(command: ApplicationCommand,
                               promise: @escaping (Result<Void, Error>) -> Void) {
    if command.modifiers.contains(.background) {
      launchApplication(command, completion: { error in
        if let error = error {
          promise(.failure(error))
        } else {
          promise(.success(()))
        }
      })
      return
    }

    if command.application.metadata.isElectron {
      launchApplication(command, completion: { error in
        if let error = error {
          promise(.failure(error))
        } else {
          promise(.success(()))
        }
      })
      return
    }

    let isFrontMostApplication = command.application
      .bundleIdentifier == workspace.frontApplication?.bundleIdentifier

    if isFrontMostApplication, activateApplication(command) != nil {
      if !windowListProvider.windowOwners().contains(command.application.bundleName) {
        launchApplication(command, completion: { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        })
      } else {
        promise(.success(()))
      }
    } else {
      launchApplication(command) { error in
        if let error = error {
          promise(.failure(error))
        } else if !self.windowListProvider.windowOwners().contains(command.application.bundleName) {
          if let error = self.activateApplication(command) {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        } else {
          promise(.success(()))
        }
      }
    }
  }

  private func closeApplication(command: ApplicationCommand,
                                promise: @escaping (Result<Void, Error>) -> Void) {
    guard let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
      command.application.bundleIdentifier == $0.bundleIdentifier
    }) else {
      promise(.failure(ApplicationCommandControllingError.failedToClose))
      return
    }

    if !runningApplication.terminate() {
      promise(.failure(ApplicationCommandControllingError.failedToClose))
    }
  }

  /// Launch an application using the applications bundle identifier
  /// Applications are launched using `NSWorkspace`
  ///
  /// - Parameter command: An application command which is used to resolve the applications
  ///                      bundle identifier.
  /// - Throws: If `NSWorkspace.launchApplication` returns `false`, the method will throw
  ///           `ApplicationCommandControllingError.failedToLaunch`
  private func launchApplication(_ command: ApplicationCommand, completion: @escaping (Error?) -> Void) {
    let config = NSWorkspace.OpenConfiguration()

    config.activates = !command.modifiers.contains(.background)
    config.hides = command.modifiers.contains(.hidden)

    workspace.open(URL(fileURLWithPath: command.application.path), config: config) { _, error in
      completion(error)
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
  private func activateApplication(_ command: ApplicationCommand) -> Error? {
    guard
      let runningApplication = workspace
        .applications
        .first(where:
                { $0.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() }
        ) else {
      return ApplicationCommandControllingError.failedToFindRunningApplication
    }

    var options: NSApplication.ActivationOptions = .activateIgnoringOtherApps

    if workspace.frontApplication?.bundleIdentifier?.lowercased() == command.application.bundleIdentifier.lowercased() {
      options.insert(.activateAllWindows)
    }

    if !runningApplication.activate(options: options) {
      return ApplicationCommandControllingError.failedToActivate
    } else {
      return nil
    }
  }
}
