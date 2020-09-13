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
  func run(_ command: OpenCommand) throws
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

  func run(_ command: OpenCommand) throws {
    let path = command.path.sanitizedPath
    let url = URL(fileURLWithPath: path)
    let config = NSWorkspace.OpenConfiguration()

    if let application = command.application {
      let applicationUrl = URL(fileURLWithPath: application.path)
      workspace.open([url], withApplicationAt: applicationUrl,
                     config: config) { [weak self] runningApplication, error in
        guard let self = self else { return }
        self.handleWorkspaceResult(command: command, runningApplication: runningApplication, error: error)
      }
    } else {
      workspace.open(url, config: config, completionHandler: { [weak self] runningApplication, error in
        guard let self = self else { return }
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
