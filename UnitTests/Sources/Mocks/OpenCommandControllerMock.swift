import Combine
import LogicFramework

class OpenCommandControllerMock: OpenCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: OpenCommand) -> AnyPublisher<Void, Error> {
    result.publisher.eraseToAnyPublisher()
  }
}
