@testable import LogicFramework
import Combine
import Cocoa

class ShellScriptControllerMock: ShellScriptControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ source: ScriptCommand.Source) -> AnyPublisher<Void, Error> {
    result.publisher.eraseToAnyPublisher()
  }
}
