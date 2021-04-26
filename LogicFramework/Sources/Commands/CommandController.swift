import Combine
import Foundation
import ModelKit

public typealias CommandPublisher = AnyPublisher<Void, Error>

public protocol CommandControllingDelegate: AnyObject {
  func commandController(_ controller: CommandController, failedRunning command: Command,
                         with error: Error,
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

public final class CommandController: CommandControlling {
  weak public var delegate: CommandControllingDelegate?

  let applicationCommandController: ApplicationCommandControlling
  let builtInCommandController: BuiltInCommandControlling
  let keyboardCommandController: KeyboardCommandControlling
  let openCommandController: OpenCommandControlling
  let appleScriptCommandController: AppleScriptControlling
  let shellScriptCommandController: ShellScriptControlling
  let queue: DispatchQueue = .init(label: "com.zenangst.Keyboard-Cowboy.CommandControllerQueue",
                                   qos: .userInitiated)

  var currentQueue = [Command]()
  var finishedCommands = [Command]()
  var cancellables = Set<AnyCancellable>()

  init(appleScriptCommandController: AppleScriptControlling,
       applicationCommandController: ApplicationCommandControlling,
       builtInCommandController: BuiltInCommandControlling,
       keyboardCommandController: KeyboardCommandControlling,
       openCommandController: OpenCommandControlling,
       shellScriptCommandController: ShellScriptControlling) {
    self.appleScriptCommandController = appleScriptCommandController
    self.applicationCommandController = applicationCommandController
    self.builtInCommandController = builtInCommandController
    self.keyboardCommandController = keyboardCommandController
    self.openCommandController = openCommandController
    self.shellScriptCommandController = shellScriptCommandController
  }

  // MARK: Public methods

  public func run(_ commands: [Command]) {
    queue.async { [weak self] in
      guard let self = self else { return }
      let shouldRun = self.currentQueue.isEmpty
      self.currentQueue.append(contentsOf: commands)
      if shouldRun {
        self.runQueue()
      }
    }
  }

  // MARK: Private methods

  private func run(_ command: Command) {
    switch command {
    case .application(let applicationCommand):
      subscribeToPublisher(applicationCommandController.run(applicationCommand), for: command)
    case .builtIn(let builtInCommand):
      subscribeToPublisher(builtInCommandController.run(builtInCommand), for: command)
    case .keyboard(let keyboardCommand):
      subscribeToPublisher(keyboardCommandController.run(keyboardCommand,
                                                         type: .keyDown,
                                                         eventSource: nil), for: command)
    case .type(let command):
      handle(command)
    case .open(let openCommand):
      subscribeToPublisher(openCommandController.run(openCommand), for: command)
    case .script(let scriptCommand):
      handle(scriptCommand, command: command)
    }
  }

  private func handle(_ scriptCommand: ScriptCommand, command: Command) {
    switch scriptCommand {
    case .appleScript(_, _, let source):
      subscribeToPublisher(appleScriptCommandController.run(source), for: command)
    case .shell(_, _, let source):
      subscribeToPublisher(shellScriptCommandController.run(source), for: command)
    }
  }

  private func handle(_ command: TypeCommand) {
    for key in command.input.compactMap(String.init) {
      var modifiers = [ModifierKey]()

      if key.uppercased() == key {
        modifiers.append(.shift)
      }

      let keyboardCommand = KeyboardCommand(
        keyboardShortcut:
          KeyboardShortcut(key: key, modifiers: modifiers))

      let command = Command.keyboard(keyboardCommand)

      // Invoke keyboard command controller on the main thread.
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.subscribeToPublisher(self.keyboardCommandController.run(keyboardCommand,
                                                           type: .keyDown,
                                                           eventSource: nil), for: command)
        self.subscribeToPublisher(self.keyboardCommandController.run(keyboardCommand,
                                                           type: .keyUp,
                                                           eventSource: nil), for: command)
      }
    }
  }

  private func subscribeToPublisher(_ publisher: CommandPublisher, for command: Command) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.delegate?.commandController(self, runningCommand: command)
    }

    publisher
      .receive(on: queue)
      .sink(
        receiveCompletion: { [weak self] completion in
          guard let self = self else { return }
          switch completion {
          case .failure(let error):
            if case let .application(command) = command,
               command.application.metadata.isAgent {
              self.runQueue()
            } else {
              self.abortQueue(command, error: error)
            }
          case .finished:
            self.cancellables.removeAll()
            self.runQueue()
          }
        },
        receiveValue: {}
      )
      .store(in: &cancellables)
  }

  private func abortQueue(_ command: Command, error: Error) {
    var commands: [Command] = finishedCommands
    commands.append(contentsOf: currentQueue)
    currentQueue.removeAll()

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      switch error {
      case let error as AppleScriptControllingError:
        self.handle(error, command: command, commands: commands)
      case let error as ApplicationCommandControllingError:
        self.handle(error, command: command, commands: commands)
      case let error as OpenCommandControllingError:
        self.handle(error, command: command, commands: commands)
      case let error as ShellScriptControllingError:
        self.handle(error, command: command, commands: commands)
      default:
        break
      }
    }
  }

  private func runQueue() {
    if !currentQueue.isEmpty {
      let currentItem = currentQueue.remove(at: 0)
      finishedCommands.append(currentItem)
      run(currentItem)
    } else {
      let finishedCommands = self.finishedCommands
      self.finishedCommands.removeAll()
      self.cancellables.removeAll()
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.delegate?.commandController(self, didFinishRunning: finishedCommands)
      }
    }
  }

  // MARK: Error handling

  private func handle(_ appleScriptError: AppleScriptControllingError,
                      command: Command,
                      commands: [Command]) {
    switch appleScriptError {
    case .failedToCreateInlineAppleScript,
         .failedToLoadAppleScriptAtUrl,
         .failedToRunAppleScript:
      delegate?.commandController(self, failedRunning: command,
                                  with: appleScriptError, commands: commands)
    }
  }

  private func handle(_ applicationError: ApplicationCommandControllingError,
                      command: Command,
                      commands: [Command]) {
    switch applicationError {
    case .failedToActivate,
         .failedToFindRunningApplication,
         .failedToLaunch,
         .failedToClose:
      delegate?.commandController(self, failedRunning: command,
                                  with: applicationError, commands: commands)
    }
  }

  private func handle(_ openCommandError: OpenCommandControllingError,
                      command: Command,
                      commands: [Command]) {
    switch openCommandError {
    case .failedToOpenUrl:
      self.delegate?.commandController(self, failedRunning: command,
                                       with: openCommandError, commands: commands)
    }
  }

  private func handle(_ shellCommandError: ShellScriptControllingError,
                      command: Command,
                      commands: [Command]) {
    switch shellCommandError {
    case .failedToRunShellScript:
      self.delegate?.commandController(self, failedRunning: command,
                                       with: shellCommandError, commands: commands)
    }
  }
}
