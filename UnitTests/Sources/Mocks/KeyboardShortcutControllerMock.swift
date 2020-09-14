@testable import LogicFramework
import Combine
import Cocoa

class KeyboardShortcutControllerMock: KeyboardCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: KeyboardCommand) -> AnyPublisher<Void, Error> {
    result.publisher.eraseToAnyPublisher()
  }
}
