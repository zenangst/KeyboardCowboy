import Combine
import Cocoa

public protocol OpenCommandControlling {
  /// Execute an open command either with or without an optional associated application.
  /// `NSWorkspace` is used to perform open invocations.
  ///
  /// If an application is attached to the `OpenCommand`, then
  /// `open(_ urls: [URL] ... withApplicationAt: URL)` is invoked on `NSWorkspace`.
  ///
  /// If an application is not selected, then `open(_ url: URL ...)` will be used.
  ///
  /// - Note: All calls are made asynchronously.
  /// - Parameter command: An `OpenCommand` that should be invoked.
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ command: OpenCommand) -> CommandPublisher
}

public enum OpenCommandControllingError: Error {
  case failedToOpenUrl
}

class OpenCommandController: OpenCommandControlling {
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func run(_ command: OpenCommand) -> CommandPublisher {
    Future { [weak self] promise in
      let path = command.path.sanitizedPath
      let url = URL(fileURLWithPath: path)
      let config = NSWorkspace.OpenConfiguration()

      func complete(application: RunningApplication?, error: Error?) {
        if error != nil {
          promise(.failure(OpenCommandControllingError.failedToOpenUrl))
        } else {
          promise(.success(()))
        }
      }

      if let application = command.application {
        let applicationUrl = URL(fileURLWithPath: application.path)
        self?.workspace.open([url], withApplicationAt: applicationUrl, config: config, completionHandler: complete)
      } else {
        self?.workspace.open(url, config: config, completionHandler: complete)
      }
    }.eraseToAnyPublisher()
  }
}
