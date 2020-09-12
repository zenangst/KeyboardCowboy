import Foundation
import LogicFramework

class OpenCommandControllerDelegateMock: OpenCommandControllingDelegate {
  typealias OutputHandler = (Output) -> Void
  enum Output {
    case failedRunning(OpenCommand, OpenCommandControllingError)
    case finished(OpenCommand)
  }

  let handler: OutputHandler

  init(_ handler: @escaping OutputHandler) {
    self.handler = handler
  }

  func openCommandControlling(_ controller: OpenCommandControlling, didOpenCommand command: OpenCommand) {
    handler(.finished(command))
  }

  func openCommandControlling(_ controller: OpenCommandControlling,
                              didFailOpeningCommand command: OpenCommand, error: OpenCommandControllingError) {
    handler(.failedRunning(command, error))
  }
}
