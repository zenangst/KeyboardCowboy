import Foundation

public protocol CommandControllingDelegate: AnyObject {
  func commandController(_ controller: CommandController, didFinishRunning commands: [Command])
}

public protocol CommandControlling {
  var delegate: CommandControllingDelegate? { get set }
  func run(_ commands: [Command])
}

public class CommandController: CommandControlling {
  weak public var delegate: CommandControllingDelegate?

  init() {}

  public func run(_ commands: [Command]) {
    commands.forEach(run)
    delegate?.commandController(self, didFinishRunning: commands)
  }

  private func run(_ command: Command) {
    switch command {
    case .application:
      break
    case .keyboard:
      break
    case .open:
      break
    case .script:
      break
    }
  }
}
