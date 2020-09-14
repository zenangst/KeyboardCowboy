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
      appleScriptCommandController: AppleScriptControllerMock { $0.send(completion: .finished) },
      applicationCommandController: ApplicationCommandControllerMock { $0.send(completion: .finished) },
      openCommandController: OpenCommandControllerMock { $0.send(completion: .finished) },
      shellScriptCommandController: ShellScriptControllerMock { $0.send(completion: .finished) }
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
      applicationCommandController: ApplicationCommandControllerMock {
        $0.send(completion: .failure(ApplicationCommandControllingError.failedToLaunch(applicationCommand)))
      }
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
}
