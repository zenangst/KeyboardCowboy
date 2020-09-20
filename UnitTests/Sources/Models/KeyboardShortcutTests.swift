@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class KeyboardShortcutTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().keyboardShortcut().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let modifiers = [ModifierKey.control, ModifierKey.option]
    let json: [String: AnyHashable] = [
      "key": "A",
      "modifiers": modifiers.compactMap({ $0.rawValue })
    ]
    XCTAssertEqual(try KeyboardShortcut.decode(from: json),
                   ModelFactory().keyboardShortcut(key: "A", modifiers: modifiers))
  }
}
