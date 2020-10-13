@testable import LogicFramework
import Combine
import Cocoa
import ModelKit

class ShellScriptControllerMock: ShellScriptControlling {
  let result: Result<Void, Error>

  init(_ result: Result<Void, Error>) {
    self.result = result
  }

  func run(_ source: ScriptCommand.Source) -> CommandPublisher {
    result.publisher.eraseToAnyPublisher()
  }
}
