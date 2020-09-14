import Combine
import Foundation

public protocol KeyboardCommandControlling {
  func run(_ command: KeyboardCommand) -> AnyPublisher<Void, Error>
}

public enum KeyboardCommandControllingError: Error {
  case failedToRunCommand(Error)
}

class KeyboardCommandController: KeyboardCommandControlling {
  func run(_ command: KeyboardCommand) -> AnyPublisher<Void, Error> {
    Result.success(()).publisher.eraseToAnyPublisher()
  }
}
