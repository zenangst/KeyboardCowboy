@testable import LogicFramework
import XCTest
@testable import ModelKit

class OpenCommandControllerTests: XCTestCase {
  func testOpenCommandControllerOpeningFileWithDefaultApplication() {
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.Finder")
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (runningApplication, nil))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand()

    _ = controller.run(openCommand).sink(
      receiveCompletion: { result in
        switch result {
        case .failure:
          XCTFail("Ended up with wrong state.")
        case .finished:
          fileOpenCommandExpectation.fulfill()
        }
      }, receiveValue: { _ in })

    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }

  func testOpenCommandControllerOpeningFileWithApplication() {
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.Finder")
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (runningApplication, nil))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand(application: nil)

    _ = controller.run(openCommand).sink(
      receiveCompletion: { result in
        switch result {
        case .failure:
          XCTFail("Ended up with wrong state.")
        case .finished:
          fileOpenCommandExpectation.fulfill()
        }
      }, receiveValue: { _ in })

    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }

  func testOpenCommandControllerFailingToOpenFile() {
    let fileOpenCommandExpectation = self.expectation(description: "Wait for command to launch")
    let workspace = WorkspaceProviderMock(openFileResult: (nil, OpenCommandControllingError.failedToOpenUrl))
    let controller = OpenCommandController(workspace: workspace)
    let openCommand = ModelFactory().openCommand(application: nil)

    _ = controller.run(openCommand).sink(
      receiveCompletion: { result in
        switch result {
        case .failure:
          fileOpenCommandExpectation.fulfill()
        case .finished:
          XCTFail("Ended up with wrong state.")
        }
      }, receiveValue: { _ in })

    wait(for: [fileOpenCommandExpectation], timeout: 1)
  }
}
