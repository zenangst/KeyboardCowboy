import Foundation
import LogicFramework

class CommandControllingDelegateMock: CommandControllingDelegate {
  enum CommandControllingDelegateState {
    case failedRunning(Command, commands: [Command])
    case finished([Command])
  }

  typealias Handler = (CommandControllingDelegateState) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler) {
    self.handler = handler
  }

  // MARK: CommandControllingDelegate

  func commandController(_ controller: CommandController, failedRunning command: Command, commands: [Command]) {
    handler(.failedRunning(command, commands: commands))
  }

  func commandController(_ controller: CommandController, didFinishRunning commands: [Command]) {
    handler(.finished(commands))
  }
}
