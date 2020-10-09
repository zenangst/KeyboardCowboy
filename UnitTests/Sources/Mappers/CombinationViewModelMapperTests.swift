import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class KeyboardShortcutViewModelMapperTests: XCTestCase {
  func testMappingKeyboardShortcutWithModifiers() {
    let id = UUID().uuidString
    let subject = [
      KeyboardShortcut(
        id: id,
        key: "A",
        modifiers: [.control, .option, .command])]
    let expected = [KeyboardShortcutViewModel(id: id, key: "A", modifiers: [.control, .option, .command])]
    let mapper = KeyboardShortcutViewModelMapper()
    let result = mapper.map(subject)

    XCTAssertEqual(expected, result)
  }

  func testMappingKeyboardShortcutWithoutModifiers() {
    let id = UUID().uuidString
    let subject = [
      KeyboardShortcut(
        id: id,
        key: "A",
        modifiers: nil)]
    let expected = [KeyboardShortcutViewModel(id: id, key: "A")]
    let mapper = KeyboardShortcutViewModelMapper()
    let result = mapper.map(subject)

    XCTAssertEqual(expected, result)
  }
}
