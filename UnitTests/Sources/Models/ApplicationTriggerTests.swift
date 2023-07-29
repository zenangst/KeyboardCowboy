@testable import Keyboard_Cowboy
import XCTest

final class ApplicationTriggerTests: XCTestCase {
  func testCopy() {
    let subject = ApplicationTrigger(application: .calendar(), contexts: [.frontMost])
    let copy = subject.copy()

    XCTAssertNotEqual(subject.id, copy.id)
    XCTAssertEqual(subject.contexts, copy.contexts)
    XCTAssertEqual(subject.application, copy.application)
  }
}
