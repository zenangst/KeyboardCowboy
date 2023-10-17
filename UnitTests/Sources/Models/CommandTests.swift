@testable import Keyboard_Cowboy
import XCTest

final class CommandTests: XCTestCase {
  func testCopy() {
    let subject = Command.application(.init(name: "Test", action: .open, application: .calendar(), modifiers: [.onlyIfNotRunning], notification: true))
    let copy = subject.copy()

    XCTAssertNotEqual(subject.id, copy.id)
    XCTAssertEqual(subject.name, copy.name)
    XCTAssertEqual(subject.notification, copy.notification)

    XCTAssertNotEqual(subject.meta.id, copy.meta.id)
    XCTAssertEqual(subject.meta.name, copy.meta.name)
    XCTAssertEqual(subject.meta.delay, copy.meta.delay)
    XCTAssertEqual(subject.meta.isEnabled, copy.meta.isEnabled)
    XCTAssertEqual(subject.meta.notification, copy.meta.notification)
  }
}
