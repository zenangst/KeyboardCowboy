import Combine
import Foundation

public protocol KeyboardCommandControlling: CommandPublishing {
  func run(_ command: KeyboardCommand)
}

public enum KeyboardCommandControllingError: Error {
  case failedToRunCommand(Error)
}

class KeyboardCommandController: KeyboardCommandControlling {
  var publisher: AnyPublisher<Command, Error> {
    subject.eraseToAnyPublisher()
  }
  private let subject = PassthroughSubject<Command, Error>()

  func run(_ command: KeyboardCommand) {
    subject.send(completion: .finished)
  }
}
