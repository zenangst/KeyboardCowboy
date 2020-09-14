import Combine
import LogicFramework

class OpenCommandControllerMock: OpenCommandControlling {
  var publisher: AnyPublisher<Command, Error> {
    subject.eraseToAnyPublisher()
  }
  private let subject = PassthroughSubject<Command, Error>()

  typealias Handler = (PassthroughSubject<Command, Error>) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler = { _ in }) {
    self.handler = handler
  }

  func run(_ command: OpenCommand) {
    handler(subject)
  }
}
