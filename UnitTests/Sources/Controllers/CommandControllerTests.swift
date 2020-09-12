import XCTest
@testable import LogicFramework

class CommandControllerTests: XCTestCase {
  let modelFactory = ModelFactory()
  let controllerFactory = ControllerFactory()

  func testCommandControllerRunningCommandsSuccessfully() throws {
    let commands: [Command] = [
      .application(modelFactory.applicationCommand()),
      .keyboard(modelFactory.keyboardCommand()),
      .open(modelFactory.openCommand()),
      .script(modelFactory.scriptCommand(.appleScript(.inline(""))))
    ]
    let controller = controllerFactory.commandController(
      applicationCommandController: ApplicationCommandControllerMock(),
      openCommandController: OpenCommandControllerMock())
    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = CommandControllingDelegateMock { state in
      switch state {
      case .failedRunning:
        XCTFail("Wrong state")
      case .finished(let finishedCommands):
        XCTAssertEqual(commands, finishedCommands)
      }
      expectation.fulfill()
    }

    controller.delegate = delegate
    try controller.run(commands)
    wait(for: [expectation], timeout: 10)
  }

  func testCommandControllerRunningFailingToLaunchApplicationCommand() throws {
    let applicationCommand = modelFactory.applicationCommand()
    let commands: [Command] = [.application(applicationCommand)]
    let controller = controllerFactory.commandController(
      applicationCommandController: ApplicationCommandControllerMock {
        throw ApplicationCommandControllingError.failedToLaunch(applicationCommand)
      }
    )

    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = CommandControllingDelegateMock { state in
      switch state {
      case .failedRunning(let command, let invokedCommands):
        XCTAssertEqual(command, .application(applicationCommand))
        XCTAssertEqual(commands, invokedCommands)
      case .finished:
        XCTFail("Wrong state")
      }
      expectation.fulfill()
    }

    controller.delegate = delegate

    XCTAssertThrowsError(try controller.run(commands))
    wait(for: [expectation], timeout: 10)
  }
}
