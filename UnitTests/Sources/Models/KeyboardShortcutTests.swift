@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class KeyboardShortcutTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().keyboardShortcut().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "key": "A",
      "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]
    ]
    XCTAssertEqual(try KeyboardShortcut.decode(from: json), ModelFactory().keyboardShortcut())
  }
}
