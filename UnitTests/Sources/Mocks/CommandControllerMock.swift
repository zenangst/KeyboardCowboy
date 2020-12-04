import LogicFramework
import ModelKit

class CommandControllerMock: CommandControlling {
  var delegate: CommandControllingDelegate?
  func run(_ commands: [Command]) {

  }
}
