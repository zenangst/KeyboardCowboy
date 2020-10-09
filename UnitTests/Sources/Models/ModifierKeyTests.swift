@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ViewKit
import Foundation
import XCTest

class ModifierKeyTests: XCTestCase {
  func testModifierShiftKey() {
    let key = LogicFramework.ModifierKey.shift

    XCTAssertEqual(key.rawValue, "$")
    XCTAssertEqual(key.pretty, "⇧")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.shift)
  }

  func testModifierControlKey() {
    let key = LogicFramework.ModifierKey.control

    XCTAssertEqual(key.rawValue, "^")
    XCTAssertEqual(key.pretty, "⌃")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.control)
  }

  func testModifierOptionKey() {
    let key = LogicFramework.ModifierKey.option

    XCTAssertEqual(key.rawValue, "~")
    XCTAssertEqual(key.pretty, "⌥")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.option)
  }

  func testModifierCommandKey() {
    let key = LogicFramework.ModifierKey.command

    XCTAssertEqual(key.rawValue, "@")
    XCTAssertEqual(key.pretty, "⌘")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.command)
  }

  func testModifierFunctionKey() {
    let key = LogicFramework.ModifierKey.function

    XCTAssertEqual(key.rawValue, "fn")
    XCTAssertEqual(key.pretty, "ƒ")
    XCTAssertEqual(key.modifierFlags, NSEvent.ModifierFlags.function)
  }

  func testModifierKeysFromNSEvent() {
    let subject: NSEvent.ModifierFlags = [
      .shift, .function, .control, .option, .command
    ]
    let expected: [LogicFramework.ModifierKey] = [
      .shift, .function, .control, .option, .command
    ]

    let result = LogicFramework.ModifierKey.fromNSEvent(subject)

    XCTAssertEqual(expected, result)
  }

  func testSwappingNamespace() {
    let logicModifiers: [LogicFramework.ModifierKey] = [
      .shift, .function, .control, .option, .command
    ]
    let viewKitModifiers: [ViewKit.ModifierKey] = [
      .shift, .function, .control, .option, .command
    ]

    XCTAssertEqual(logicModifiers, viewKitModifiers.swapNamespace)
    XCTAssertEqual(viewKitModifiers, logicModifiers.swapNamespace)
  }
}
