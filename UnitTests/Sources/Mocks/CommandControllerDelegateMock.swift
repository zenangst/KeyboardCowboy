import Foundation
import LogicFramework
import ModelKit

class CommandControllerDelegateMock: CommandControllingDelegate {
  enum Output {
    case running(Command)
    case failedRunning(Command, commands: [Command])
    case finished([Command])
  }

  typealias Handler = (Output) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler) {
    self.handler = handler
  }

  // MARK: CommandControllingDelegate

  func commandController(_ controller: CommandController, runningCommand command: Command) {
    handler(.running(command))
  }

  func commandController(_ controller: CommandController, didFinishRunning commands: [Command]) {
    handler(.finished(commands))
  }

  func commandController(_ controller: CommandController, failedRunning command: Command, commands: [Command]) {
    handler(.failedRunning(command, commands: commands))
  }
}
