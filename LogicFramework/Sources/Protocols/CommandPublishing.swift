import Combine

public protocol CommandPublishing {
  var publisher: AnyPublisher<Command, Error> { get }
}
