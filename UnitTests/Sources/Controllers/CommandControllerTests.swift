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
      .script(.appleScript(.inline(""))),
      .script(.shell(.inline("")))
    ]
    let controller = controllerFactory.commandController(
      appleScriptCommandController: AppleScriptControllerMock {
        $0.send(completion: .finished)
      },
      applicationCommandController: ApplicationCommandControllerMock {
        $0.send(completion: .finished)
      },
      openCommandController: OpenCommandControllerMock {
        $0.send(completion: .finished)
      },
      shellScriptCommandController: ShellScriptControllerMock {
        $0.send(completion: .finished)
      }
    )
    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = CommandControllerDelegateMock { state in
      switch state {
      case .failedRunning:
        XCTFail("Wrong state")
      case .finished(let finishedCommands):
        XCTAssertEqual(commands, finishedCommands)
      }
      expectation.fulfill()
    }

    controller.delegate = delegate
    controller.run(commands)
    wait(for: [expectation], timeout: 10)
  }

  func testCommandControllerRunningFailingToLaunchApplicationCommand() throws {
    let applicationCommand = modelFactory.applicationCommand()
    let commands: [Command] = [.application(applicationCommand)]
    let controller = controllerFactory.commandController(
      applicationCommandController: ApplicationCommandControllerMock {
        $0.send(completion: .failure(ApplicationCommandControllingError.failedToLaunch(applicationCommand)))
      }
    )

    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = CommandControllerDelegateMock { state in
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

    controller.run(commands)
    wait(for: [expectation], timeout: 10)
  }
}
