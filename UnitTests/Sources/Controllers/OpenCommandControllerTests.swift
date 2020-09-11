@testable import LogicFramework
import XCTest

class OpenCommandControllerTests: XCTestCase {
  func testOpenCommandControllerOpeningFileWithDefaultApplication() throws {
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.Finder")
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (runningApplication, nil))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand()
    let delegate = OpenCommandControllerDelegateMock { output in
      switch output {
      case .failedRunning:
        XCTFail("Ended up with wrong state.")
      case .finished(let command):
        XCTAssertEqual(command, openCommand)
        fileOpenCommandExpectation.fulfill()
      }
    }
    controller.delegate = delegate
    controller.run(openCommand)
    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }

  func testOpenCommandControllerOpeningFileWithApplication() {
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.Finder")
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (runningApplication, nil))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand(application: nil)
    let delegate = OpenCommandControllerDelegateMock { output in
      switch output {
      case .failedRunning:
        XCTFail("Ended up with wrong state.")
      case .finished(let command):
        XCTAssertEqual(command, openCommand)
        fileOpenCommandExpectation.fulfill()
      }
    }
    controller.delegate = delegate
    controller.run(openCommand)
    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }

  func testOpenCommandControllerFailingToOpenFile() {
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (nil, OpenCommandControllingError.failedToOpenUrl))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand(application: nil)
    let delegate = OpenCommandControllerDelegateMock { output in
      switch output {
      case .failedRunning(let command, _):
        XCTAssertEqual(command, openCommand)
        fileOpenCommandExpectation.fulfill()
      case .finished:
        XCTFail("Ended up with wrong state.")
      }
    }
    controller.delegate = delegate
    controller.run(openCommand)
    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }
}
