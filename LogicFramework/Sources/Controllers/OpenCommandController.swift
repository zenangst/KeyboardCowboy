import Cocoa

public protocol OpenCommandControlling {
  func run(_ command: OpenCommand)
}

public protocol OpenCommandControllingDelegate: AnyObject {
  func openCommandControlling(_ controller: OpenCommandControlling,
                              didOpenCommand command: OpenCommand)
  func openCommandControlling(_ controller: OpenCommandControlling,
                              didFailOpeningCommand command: OpenCommand,
                              error: OpenCommandControllingError)
}

public enum OpenCommandControllingError: Error {
  case failedToOpenUrl
}

class OpenCommandController: OpenCommandControlling {
  weak var delegate: OpenCommandControllingDelegate?
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

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
  func run(_ command: OpenCommand) {
    let config = NSWorkspace.OpenConfiguration()
    if let application = command.application {
      workspace.open([command.url], withApplicationAt: application.url,
                     config: config) { runningApplication, error in
        self.handleWorkspaceResult(command: command, runningApplication: runningApplication, error: error)
      }
    } else {
      workspace.open(command.url, config: config, completionHandler: { runningApplication, error in
        self.handleWorkspaceResult(command: command, runningApplication: runningApplication, error: error)
      })
    }
  }

  private func handleWorkspaceResult(command: OpenCommand,
                                     runningApplication: RunningApplication?,
                                     error: Error?) {
    guard error == nil else {
      self.delegate?.openCommandControlling(self, didFailOpeningCommand: command,
                                            error: .failedToOpenUrl)
      return
    }

    self.delegate?.openCommandControlling(self, didOpenCommand: command)
  }
}
