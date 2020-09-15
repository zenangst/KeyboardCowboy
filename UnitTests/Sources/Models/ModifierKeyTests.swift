@testable import LogicFramework
import Foundation
import XCTest

class ModifierKeyTests: XCTestCase {
  func testModifierShiftKey() {
    let key = ModifierKey.shift

    XCTAssertEqual(key.rawValue, "$")
    XCTAssertEqual(key.pretty, "⇧")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.shift)
  }

  func testModifierControlKey() {
    let key = ModifierKey.control

    XCTAssertEqual(key.rawValue, "^")
    XCTAssertEqual(key.pretty, "⌃")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.control)
  }

  func testModifierOptionKey() {
    let key = ModifierKey.option

    XCTAssertEqual(key.rawValue, "~")
    XCTAssertEqual(key.pretty, "⌥")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.option)
  }

  func testModifierCommandKey() {
    let key = ModifierKey.command

    XCTAssertEqual(key.rawValue, "@")
    XCTAssertEqual(key.pretty, "⌘")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.command)
  }
}
