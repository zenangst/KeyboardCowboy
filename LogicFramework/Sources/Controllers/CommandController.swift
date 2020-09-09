import Foundation

public protocol CommandControllingDelegate: AnyObject {
  func commandController(_ controller: CommandController, failedRunning command: Command,
                         commands: [Command])
  func commandController(_ controller: CommandController, didFinishRunning commands: [Command])
}

public protocol CommandControlling: AnyObject {
  var delegate: CommandControllingDelegate? { get set }
  func run(_ commands: [Command]) throws
}

public class CommandController: CommandControlling {
  weak public var delegate: CommandControllingDelegate?

  let applicationCommandController: ApplicationCommandControlling

  init(applicationCommandController: ApplicationCommandControlling) {
    self.applicationCommandController = applicationCommandController
  }

  // MARK: Public methods

  public func run(_ commands: [Command]) throws {
    do {
      try commands.forEach(run)
      delegate?.commandController(self, didFinishRunning: commands)
    } catch let error {
      if let applicationError = error as? ApplicationCommandControllingError {
        switch applicationError {
        case .failedToActivate(let command),
             .failedToFindRunningApplication(let command),
             .failedToLaunch(let command):
          delegate?.commandController(
            self,
            failedRunning: .application(command),
            commands: commands)
        }
        throw error
      }
    }
  }

  // MARK: Private methods

  private func run(_ command: Command) throws {
    switch command {
    case .application(let command):
      try applicationCommandController.run(command)
    case .keyboard:
      break
    case .open:
      break
    case .script:
      break
    }
  }
}
