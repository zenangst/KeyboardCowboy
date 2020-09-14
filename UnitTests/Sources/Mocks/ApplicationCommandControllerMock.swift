import Foundation
import Combine
import LogicFramework

class ApplicationCommandControllerMock: ApplicationCommandControlling {
  var publisher: AnyPublisher<Command, Error> {
    subject.eraseToAnyPublisher()
  }
  private let subject = PassthroughSubject<Command, Error>()

  typealias Handler = (PassthroughSubject<Command, Error>) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler = { _ in }) {
    self.handler = handler
  }

  func run(_ command: ApplicationCommand) {
    handler(subject)
  }
}
