import Foundation

public protocol CommandControllingDelegate: AnyObject {
  func commandController(_ controller: CommandController, failedRunning command: Command,
                         commands: [Command])
  func commandController(_ controller: CommandController, didFinishRunning commands: [Command])
}

public protocol CommandControlling: AnyObject {
  var delegate: CommandControllingDelegate? { get set }
  /// Run a collection of `Command`´s in sequential order,
  /// if one command fails, the entire chain should stop.
  ///
  /// - Parameter commands: A collection of `Command`'s that
  ///                       should be executed.
  func run(_ commands: [Command]) throws
}

public class CommandController: CommandControlling {
  weak public var delegate: CommandControllingDelegate?

  let applicationCommandController: ApplicationCommandControlling
  let openCommandController: OpenCommandControlling
  let scriptCommandController: ScriptCommandControlling

  init(applicationCommandController: ApplicationCommandControlling,
       openCommandController: OpenCommandControlling,
       scriptCommandController: ScriptCommandControlling) {
    self.applicationCommandController = applicationCommandController
    self.openCommandController = openCommandController
    self.scriptCommandController = scriptCommandController
  }

  // MARK: Public methods

  public func run(_ commands: [Command]) throws {
    do {
      try commands.forEach(run)
      delegate?.commandController(self, didFinishRunning: commands)
    } catch let error {
      if let applicationError = error as? ApplicationCommandControllingError {
        handle(applicationError, commands: commands)
      }
      throw error
    }
  }

  // MARK: Private methods

  private func run(_ command: Command) throws {
    switch command {
    case .application(let command):
      try applicationCommandController.run(command)
    case .keyboard:
      break
    case .open(let command):
      try openCommandController.run(command)
    case .script(let scriptCommand):
      try scriptCommandController.run(scriptCommand)
    }
  }

  private func handle(_ applicationError: ApplicationCommandControllingError,
                      commands: [Command]) {
    switch applicationError {
    case .failedToActivate(let command),
         .failedToFindRunningApplication(let command),
         .failedToLaunch(let command):
      delegate?.commandController(
        self,
        failedRunning: .application(command),
        commands: commands)
    }
  }
}
