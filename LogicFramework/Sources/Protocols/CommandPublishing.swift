import Combine

public protocol CommandPublishing {
  var publisher: AnyPublisher<Command, Error> { get }
  var subject: PassthroughSubject<Command, Error> { get }
}

public extension CommandPublishing {
  var publisher: AnyPublisher<Command, Error> {
    subject.eraseToAnyPublisher()
  }
}
