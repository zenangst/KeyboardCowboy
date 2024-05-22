@testable import Keyboard_Cowboy
import XCTest

final class ApplicationActivityMonitorTests: XCTestCase {
  @MainActor
  func testPreviousApplication() {
    let app1 = RunningApplicationMock(
      bundleIdentifier: "com.zenangst.app1",
      bundleURL: URL(string: "file:///Applications/App1.app")!,
      localizedName: "App1",
      processIdentifier: 128
    ).asApplication()!
    let app2 = RunningApplicationMock(
      bundleIdentifier: "com.zenangst.app2",
      bundleURL: URL(string: "file:///Applications/App2.app")!,
      localizedName: "App2",
      processIdentifier: 129
    ).asApplication()!
    let app3 = RunningApplicationMock(
      bundleIdentifier: "com.zenangst.app3",
      bundleURL: URL(string: "file:///Applications/App3.app")!,
      localizedName: "App3",
      processIdentifier: 130
    ).asApplication()!

    let publisher = UserSpacePublisher(current: app1)
    let monitor = ApplicationActivityMonitor()

    XCTAssertNil(monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [])

    monitor.subscribe(to: publisher.$current)
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [app1.bundleIdentifier])

    publisher.current = app2
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app1.bundleIdentifier, app2.bundleIdentifier
    ])

    publisher.current = app1
    XCTAssertEqual(app2, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app2.bundleIdentifier, app1.bundleIdentifier
    ])

    publisher.current = app3
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app2.bundleIdentifier, app1.bundleIdentifier, app3.bundleIdentifier
    ])
  }
}

private class UserSpacePublisher {
  @Published var current: UserSpace.Application

  init(current: UserSpace.Application) {
    self.current = current
  }
}

