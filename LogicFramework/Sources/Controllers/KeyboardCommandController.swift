import Combine
import Foundation

public protocol KeyboardCommandControlling {
  /// - Parameter command: A `KeyboardCommand` that should be invoked.
  /// - Returns: A publisher that wraps a result of the run operation.
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
