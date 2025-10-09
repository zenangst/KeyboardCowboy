@testable import Keyboard_Cowboy
import XCTest

final class ApplicationActivityMonitorTests: XCTestCase {
  @MainActor
  func testPreviousApplication() {
    let app1 = TestApplication(
      bundleIdentifier: "com.zenangst.app1",
      isTerminated: false,
    )
    let app2 = TestApplication(
      bundleIdentifier: "com.zenangst.app2",
      isTerminated: false,
    )
    let app3 = TestApplication(
      bundleIdentifier: "com.zenangst.app3",
      isTerminated: false,
    )

    let publisher = TestPublisher<TestApplication>(current: app1)
    let monitor = ApplicationActivityMonitor<TestApplication>()

    XCTAssertNil(monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [])

    monitor.subscribe(to: publisher.$current)
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [app1.bundleIdentifier])

    publisher.current = app2
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app1.bundleIdentifier, app2.bundleIdentifier,
    ])

    publisher.current = app1
    XCTAssertEqual(app2, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app2.bundleIdentifier, app1.bundleIdentifier,
    ])

    publisher.current = app3
    XCTAssertEqual(app1, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app2.bundleIdentifier, app1.bundleIdentifier, app3.bundleIdentifier,
    ])

    app3.isTerminated = true
    publisher.current = app1
    XCTAssertEqual(app2, monitor.previousApplication())
    XCTAssertEqual(monitor.bundleIdentifiers, [
      app2.bundleIdentifier, app1.bundleIdentifier,
    ])
  }
}

private class TestApplication: ActivityApplication, Equatable {
  var bundleIdentifier: String
  var isTerminated: Bool
  var debugDescription: String { "\(bundleIdentifier) \(isTerminated)" }

  init(bundleIdentifier: String, isTerminated: Bool) {
    self.bundleIdentifier = bundleIdentifier
    self.isTerminated = isTerminated
  }

  static func == (lhs: TestApplication, rhs: TestApplication) -> Bool {
    lhs.bundleIdentifier == rhs.bundleIdentifier &&
      lhs.isTerminated == rhs.isTerminated
  }
}
