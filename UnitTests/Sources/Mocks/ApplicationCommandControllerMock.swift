import Foundation
import Combine
import LogicFramework

class ApplicationCommandControllerMock: ApplicationCommandControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: ApplicationCommand) -> CommandPublisher {
    result.publisher.eraseToAnyPublisher()
  }
}
