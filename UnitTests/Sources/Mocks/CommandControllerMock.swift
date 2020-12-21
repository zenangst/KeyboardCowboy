import LogicFramework
import ModelKit

class CommandControllerMock: CommandControlling {
  typealias Handler = ([Command]) -> Void
  var handler: Handler

  init(_ handler: @escaping Handler) {
    self.handler = handler
  }

  weak var delegate: CommandControllingDelegate?
  func run(_ commands: [Command]) {
    handler(commands)
  }
}
