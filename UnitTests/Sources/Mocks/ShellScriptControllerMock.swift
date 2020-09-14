@testable import LogicFramework
import Combine
import Cocoa

class ShellScriptControllerMock: ShellScriptControlling {
  var subject = PassthroughSubject<Command, Error>()

  typealias Handler = (PassthroughSubject<Command, Error>) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler = { _ in }) {
    self.handler = handler
  }

  func run(_ command: ScriptCommand.Source) {
    handler(subject)
  }
}
