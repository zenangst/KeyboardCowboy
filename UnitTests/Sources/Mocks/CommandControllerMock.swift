import LogicFramework
import ModelKit

class CommandControllerMock: CommandControlling {
  weak var delegate: CommandControllingDelegate?
  func run(_ commands: [Command]) {}
}
