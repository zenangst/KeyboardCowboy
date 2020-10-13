@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ViewKit
import Foundation
import XCTest
import ModelKit

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

  func testModifierFunctionKey() {
    let key = ModifierKey.function

    XCTAssertEqual(key.rawValue, "fn")
    XCTAssertEqual(key.pretty, "ƒ")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.function)
  }

  func testModifierKeysFromNSEvent() {
    let subject: NSEvent.ModifierFlags = [
      .shift, .function, .control, .option, .command
    ]
    let expected: [ModifierKey] = [
      .shift, .function, .control, .option, .command
    ]

    let result = ModifierKey.fromNSEvent(subject)

    XCTAssertEqual(expected, result)
  }
}
