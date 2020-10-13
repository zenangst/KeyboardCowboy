import Combine
import LogicFramework
import ModelKit

class OpenCommandControllerMock: OpenCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: OpenCommand) -> CommandPublisher {
    result.publisher.eraseToAnyPublisher()
  }
}
