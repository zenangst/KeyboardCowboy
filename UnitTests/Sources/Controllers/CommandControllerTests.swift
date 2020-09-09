import XCTest
@testable import LogicFramework

class CommandControllerTests: XCTestCase {
  func testCommandControllerRunningCommands() {
    let factory = ModelFactory()
    let commands: [Command] = [
      .application(factory.applicationCommand()),
      .keyboard(factory.keyboardCommand()),
      .open(factory.openCommand()),
      .script(factory.scriptCommand(.appleScript(.inline(""))))
    ]
    let controller = CommandController()
    let expectation = self.expectation(description: "Wait for commands to run")
    let delegate = Delegate { finishedCommands in
      XCTAssertEqual(commands, finishedCommands)
      expectation.fulfill()
    }

    controller.delegate = delegate
    controller.run(commands)
    wait(for: [expectation], timeout: 10)
  }
}

private class Delegate: CommandControllingDelegate {
  typealias Handler = ([Command]) -> Void
  let handler: Handler

  init(_ handler: @escaping Handler) {
    self.handler = handler
  }

  func commandController(_ controller: CommandController, didFinishRunning commands: [Command]) {
    handler(commands)
  }
}
