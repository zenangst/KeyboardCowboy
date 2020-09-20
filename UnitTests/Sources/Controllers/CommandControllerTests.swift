import XCTest
@testable import LogicFramework

class CommandControllerTests: XCTestCase {
  let modelFactory = ModelFactory()
  let controllerFactory = ControllerFactory()

  func testCommandControllerRunningCommandsSuccessfully() {
    let commands: [Command] = [
      .application(modelFactory.applicationCommand()),
      .keyboard(modelFactory.keyboardCommand()),
      .open(modelFactory.openCommand()),
      .script(.appleScript(.inline(""))),
      .script(.shell(.inline("")))
    ]
    let controller = controllerFactory.commandController(
      appleScriptCommandController: AppleScriptControllerMock(.success(())),
      applicationCommandController: ApplicationCommandControllerMock(.success(())),
      openCommandController: OpenCommandControllerMock(.success(())),
      shellScriptCommandController: ShellScriptControllerMock(.success(()))
    )
    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = CommandControllerDelegateMock { state in
      switch state {
      case .running:
        break
      case .failedRunning:
        XCTFail("Wrong state")
      case .finished(let finishedCommands):
        XCTAssertEqual(commands, finishedCommands)
        expectation.fulfill()
      }
    }

    controller.delegate = delegate
    controller.run(commands)
    wait(for: [expectation], timeout: 10)
  }

  func testCommandControllerRunningFailingToLaunchApplicationCommand() {
    let applicationCommand = modelFactory.applicationCommand()
    let commands: [Command] = [.application(applicationCommand)]
    let controller = controllerFactory.commandController(
      applicationCommandController: ApplicationCommandControllerMock(
         .failure(ApplicationCommandControllingError.failedToLaunch(applicationCommand))
      )
    )

    let runningExpectation = self.expectation(description: "Wait for commands to run")
    let failureExpectation = self.expectation(description: "Wait for commands to fail")
    let delegate = CommandControllerDelegateMock { state in
      switch state {
      case .running:
        runningExpectation.fulfill()
      case .failedRunning(let command, let invokedCommands):
        XCTAssertEqual(command, .application(applicationCommand))
        XCTAssertEqual(commands, invokedCommands)
        failureExpectation.fulfill()
      case .finished:
        XCTFail("Wrong state")
      }
    }

    controller.delegate = delegate
    controller.run(commands)
    wait(for: [runningExpectation, failureExpectation], timeout: 10, enforceOrder: true)
  }

  func testCommandControllerRunningKeyboardCommands() {
    let commands: [Command] = [
      .keyboard(KeyboardCommand(keyboardShortcut: .init(key: "A"))),
      .keyboard(KeyboardCommand(keyboardShortcut: .init(key: "B"))),
      .keyboard(KeyboardCommand(keyboardShortcut: .init(key: "C"))),
      .keyboard(KeyboardCommand(keyboardShortcut: .init(key: "D")))
    ]
    let controller = controllerFactory.commandController(
      keyboardCommandController: KeyboardShortcutControllerMock(.success(()))
    )
    let expectation = self.expectation(description: "Wait for commands to finish.")
    var runningCount = 0
    let delegate = CommandControllerDelegateMock { state in
      switch state {
      case .running(let command):
        XCTAssertEqual(commands[runningCount], command)
        runningCount += 1
      case .failedRunning:
        XCTFail("This should not fail!")
      case .finished:
        XCTAssertEqual(runningCount, 4)
        expectation.fulfill()
      }
    }

    controller.delegate = delegate
    controller.run(commands)
    wait(for: [expectation], timeout: 10.0)
  }
}
