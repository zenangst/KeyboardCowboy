@testable import Keyboard_Cowboy
import XCTest

final class KeyboardShortcutTriggerTests: XCTestCase {
  func testCopy() {
    let subject = KeyboardShortcutTrigger(shortcuts: [
      .init(key: "a", lhs: true, modifiers: [.command]),
      .init(key: "b", lhs: false, modifiers: [.option]),
    ])
    let copy = subject.copy()

    XCTAssertEqual(subject.passthrough, copy.passthrough)
    XCTAssertNotEqual(subject.shortcuts[0].id, copy.shortcuts[0].id)
    XCTAssertEqual(subject.shortcuts[0].key, copy.shortcuts[0].key)
    XCTAssertEqual(subject.shortcuts[0].lhs, copy.shortcuts[0].lhs)
    XCTAssertEqual(subject.shortcuts[0].modifiers, copy.shortcuts[0].modifiers)

    XCTAssertEqual(subject.passthrough, copy.passthrough)
    XCTAssertNotEqual(subject.shortcuts[1].id, copy.shortcuts[1].id)
    XCTAssertEqual(subject.shortcuts[1].key, copy.shortcuts[1].key)
    XCTAssertEqual(subject.shortcuts[1].lhs, copy.shortcuts[1].lhs)
    XCTAssertEqual(subject.shortcuts[1].modifiers, copy.shortcuts[1].modifiers)
  }
}
