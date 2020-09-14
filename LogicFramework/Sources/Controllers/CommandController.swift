import Combine
import Foundation

public protocol CommandControllingDelegate: AnyObject {
  func commandController(_ controller: CommandController, failedRunning command: Command,
                         commands: [Command])
  func commandController(_ controller: CommandController, runningCommand command: Command)
  func commandController(_ controller: CommandController, didFinishRunning commands: [Command])
}

public protocol CommandControlling: AnyObject {
  var delegate: CommandControllingDelegate? { get set }
  /// Run a collection of `Command`´s in sequential order,
  /// if one command fails, the entire chain should stop.
  ///
  /// - Parameter commands: A collection of `Command`'s that
  ///                       should be executed.
  func run(_ commands: [Command])
}

public enum CommandControllerError: Error {
  case failedToRunCommand(Error)
}

public class CommandController: CommandControlling {
  weak public var delegate: CommandControllingDelegate?

  let applicationCommandController: ApplicationCommandControlling
  let keyboardCommandController: KeyboardCommandControlling
  let openCommandController: OpenCommandControlling
  let appleScriptCommandController: AppleScriptControlling
  let shellScriptCommandController: ShellScriptControlling

  var currentQueue = [Command]()
  var finishedCommands = [Command]()
  var cancellable: AnyCancellable?

  init(appleScriptCommandController: AppleScriptControlling,
       applicationCommandController: ApplicationCommandControlling,
       keyboardCommandController: KeyboardCommandControlling,
       openCommandController: OpenCommandControlling,
       shellScriptCommandController: ShellScriptControlling) {
    self.appleScriptCommandController = appleScriptCommandController
    self.applicationCommandController = applicationCommandController
    self.keyboardCommandController = keyboardCommandController
    self.openCommandController = openCommandController
    self.shellScriptCommandController = shellScriptCommandController
  }

  // MARK: Public methods

  public func run(_ commands: [Command]) {
    let shouldRun = currentQueue.isEmpty
    currentQueue.append(contentsOf: commands)
    if shouldRun {
      runQueue()
    }
  }

  // MARK: Private methods

  private func run(_ command: Command) {
    switch command {
    case .application(let applicationCommand):
      subscribeToPublisher(applicationCommandController.publisher, for: command)
      applicationCommandController.run(applicationCommand)
    case .keyboard(let keyboardCommand):
      subscribeToPublisher(keyboardCommandController.publisher, for: command)
      keyboardCommandController.run(keyboardCommand)
    case .open(let openCommand):
      subscribeToPublisher(openCommandController.publisher, for: command)
      openCommandController.run(openCommand)
    case .script(let scriptCommand):
      switch scriptCommand {
      case .appleScript(let source):
        subscribeToPublisher(appleScriptCommandController.publisher, for: command)
        appleScriptCommandController.run(source)
      case .shell(let source):
        subscribeToPublisher(shellScriptCommandController.publisher, for: command)
        shellScriptCommandController.run(source)
      }
    }
  }

  private func subscribeToPublisher(_ publisher: AnyPublisher<Command, Error>, for command: Command) {
    cancellable = publisher.sink(
      receiveCompletion: { [weak self] completion in
      guard let self = self else { return }
      switch completion {
      case .failure(let error):
        self.abortQueue(command, error: error)
      case .finished:
        self.runQueue()
      }
    }, receiveValue: { [weak self] command in
      guard let self = self else { return }
      self.delegate?.commandController(self, runningCommand: command)
    })
  }

  private func abortQueue(_ command: Command, error: Error) {
    switch error {
    case let error as ApplicationCommandControllingError:
      var commands: [Command] = finishedCommands
      commands.append(contentsOf: currentQueue)
      self.handle(error, commands: commands)
    default:
      break
    }
    currentQueue.removeAll()
  }

  private func runQueue() {
    if !currentQueue.isEmpty {
      let currentItem = currentQueue.remove(at: 0)
      finishedCommands.append(currentItem)
      run(currentItem)
    } else {
      delegate?.commandController(self, didFinishRunning: finishedCommands)
      finishedCommands.removeAll()
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
