import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class CombinationViewModelMapperTests: XCTestCase {
  func testMappingKeyboardShortcutWithModifiers() {
    let id = UUID().uuidString
    let subject = [
      KeyboardShortcut(
        id: id,
        key: "A",
        modifiers: [.control, .option, .command])]
    let expected = [CombinationViewModel(id: id, name: "⌃⌥⌘A")]
    let mapper = CombinationViewModelMapper()
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
    let expected = [CombinationViewModel(id: id, name: "A")]
    let mapper = CombinationViewModelMapper()
    let result = mapper.map(subject)

    XCTAssertEqual(expected, result)
  }
}
