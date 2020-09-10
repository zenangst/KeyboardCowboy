@testable import LogicFramework
import XCTest

class ApplicationCommandControllerTests: XCTestCase {
  let controllerFactory = ControllerFactory()
  let application = Application(bundleIdentifier: "com.apple.Finder",
                                name: "Finder",
                                path: "path/to/Finder")
  lazy var windowListProvider = WindowListProviderMock([])
  lazy var workspaceProvider = WorkspaceProviderMock()
  lazy var controller = controllerFactory.applicationCommandController(windowListProvider: windowListProvider,
                                                                  workspace: workspaceProvider)

  func testApplicationCommandControllerLaunchingSuccessfully() throws {
    windowListProvider.owners = []
    workspaceProvider.applications = []
    XCTAssertNoThrow(try controller.run(.init(application: application)))
  }

  func testApplicationCommandControllerFailedToLaunch() throws {
    windowListProvider.owners = []
    workspaceProvider.applications = []
    workspaceProvider.launchApplicationResult = false
    XCTAssertThrowsError(try controller.run(.init(application: application)))
  }

  func testApplicationCommandControllerActivatingSuccessfully() throws {
    windowListProvider.owners = [application.name]
    workspaceProvider.applications = [
      RunningApplicationMock(
        activate: true,
        bundleIdentifier: application.bundleIdentifier)
    ]
    XCTAssertNoThrow(try controller.run(.init(application: application)))
  }

  func testApplicationCommandControllerActivatingFailedToFindRunningApplication() throws {
    windowListProvider.owners = [application.name]
    workspaceProvider.applications = []
    XCTAssertThrowsError(try controller.run(.init(application: application)))
  }

  func testApplicationCommandControllerActivatingFailedToActivate() throws {
    windowListProvider.owners = [application.name]
    workspaceProvider.applications = [
      RunningApplicationMock(
        activate: false,
        bundleIdentifier: application.bundleIdentifier)
    ]
    XCTAssertThrowsError(try controller.run(.init(application: application)))
  }
}
