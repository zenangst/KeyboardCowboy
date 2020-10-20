@testable import LogicFramework
import Combine
import Cocoa
import ModelKit

class KeyboardShortcutControllerMock: KeyboardCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: KeyboardCommand,
           type: CGEventType,
           eventSource: CGEventSource?) -> CommandPublisher {
    result.publisher.eraseToAnyPublisher()
  }
}
