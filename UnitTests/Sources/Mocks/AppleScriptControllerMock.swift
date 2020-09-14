@testable import LogicFramework
import Combine
import Cocoa

class AppleScriptControllerMock: AppleScriptControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ command: ScriptCommand.Source) -> AnyPublisher<Void, Error> {
    result.publisher.eraseToAnyPublisher()
  }
}
