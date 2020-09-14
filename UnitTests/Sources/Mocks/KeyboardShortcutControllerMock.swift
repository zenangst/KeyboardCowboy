@testable import LogicFramework
import Combine
import Cocoa

class KeyboardShortcutControllerMock: KeyboardCommandControlling {
  var publisher: AnyPublisher<Command, Error> {
    subject.eraseToAnyPublisher()
  }
  private let subject = PassthroughSubject<Command, Error>()

  typealias Handler = (PassthroughSubject<Command, Error>) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler = { _ in }) {
    self.handler = handler
  }

  func run(_ command: KeyboardCommand) {
    handler(subject)
  }
}
