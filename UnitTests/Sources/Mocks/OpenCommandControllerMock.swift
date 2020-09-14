import Combine
import LogicFramework

class OpenCommandControllerMock: OpenCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: OpenCommand) -> CommandPublisher {
    result.publisher.eraseToAnyPublisher()
  }
}
