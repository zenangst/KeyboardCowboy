@testable import LogicFramework
import XCTest

class ApplicationCommandControllerTests: XCTestCase {
  let controllerFactory = ControllerFactory()
  let application = ModelFactory.application()
  lazy var windowListProvider = WindowListProviderMock([])
  lazy var workspaceProvider = WorkspaceProviderMock()
  lazy var controller = controllerFactory.applicationCommandController(windowListProvider: windowListProvider,
                                                                       workspace: workspaceProvider)

  func testApplicationCommandControllerLaunchingSuccessfully() {
    windowListProvider.owners = []
    workspaceProvider.applications = []
    XCTAssertNoThrow(controller.run(.init(application: application)))
  }

  func testApplicationCommandControllerFailedToLaunch() {
    windowListProvider.owners = []
    workspaceProvider.applications = []
    workspaceProvider.launchApplicationResult = false

    let expectation = self.expectation(description: "Wait for error.")
    let cancellable = controller.publisher.sink(
      receiveCompletion: { result in
        switch result {
        case .failure(let error):
          switch error {
          case let applicationError as ApplicationCommandControllingError:
            switch applicationError {
            case .failedToActivate, .failedToFindRunningApplication:
              XCTFail("Wrong error, should be .failedToLaunch")
            case .failedToLaunch:
              expectation.fulfill()
            }
          default:
            XCTFail("Wrong error type")
          }
        case .finished:
          XCTFail("Wrong state")
        }
      }, receiveValue: { _ in })
    controller.run(.init(application: application))
    wait(for: [expectation], timeout: 10.0)
  }

  func testApplicationCommandControllerActivatingSuccessfully() {
    windowListProvider.owners = [application.bundleName]
    workspaceProvider.applications = [
      RunningApplicationMock(
        activate: true,
        bundleIdentifier: application.bundleIdentifier)
    ]
    let expectation = self.expectation(description: "Wait for finished.")
    let cancellable = controller.publisher.sink(
      receiveCompletion: { result in
        switch result {
        case .failure:
          XCTFail("Should end up in `.finished`")
        case .finished:
          expectation.fulfill()
        }
      }, receiveValue: { _ in })
    controller.run(.init(application: application))
    wait(for: [expectation], timeout: 10.0)
  }

  func testApplicationCommandControllerActivatingFailedToFindRunningApplication() {
    windowListProvider.owners = [application.bundleName]
    workspaceProvider.applications = []
    let expectation = self.expectation(description: "Wait for error.")
    let cancellable = controller.publisher.sink(
      receiveCompletion: { result in
        switch result {
        case .failure(let error):
          switch error {
          case let applicationError as ApplicationCommandControllingError:
            switch applicationError {
            case .failedToActivate, .failedToLaunch:
              XCTFail("Wrong error, should be .failedToFindRunningApplication")
            case .failedToFindRunningApplication:
              expectation.fulfill()
            }
          default:
            XCTFail("Wrong error type")
          }
        case .finished:
          XCTFail("Wrong state")
        }
      }, receiveValue: { _ in })
    controller.run(.init(application: application))
    wait(for: [expectation], timeout: 10.0)
  }

  func testApplicationCommandControllerActivatingFailedToActivate() {
    windowListProvider.owners = [application.bundleName]
    workspaceProvider.applications = [
      RunningApplicationMock(
        activate: false,
        bundleIdentifier: application.bundleIdentifier)
    ]

    let expectation = self.expectation(description: "Wait for error.")
    let cancellable = controller.publisher.sink(
      receiveCompletion: { result in
        switch result {
        case .failure(let error):
          switch error {
          case let applicationError as ApplicationCommandControllingError:
            switch applicationError {
            case .failedToFindRunningApplication, .failedToLaunch:
              XCTFail("Wrong error, should be .failedToFindRunningApplication")
            case .failedToActivate:
              expectation.fulfill()
            }
          default:
            XCTFail("Wrong error type")
          }
        case .finished:
          XCTFail("Wrong state")
        }
      }, receiveValue: { _ in })
    controller.run(.init(application: application))
    wait(for: [expectation], timeout: 10.0)
  }
}
