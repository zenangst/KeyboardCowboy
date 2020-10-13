@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class KeyboardShortcutTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().keyboardShortcut(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let modifiers = [ModifierKey.control, ModifierKey.option]
    let id = UUID().uuidString
    let subject = ModelFactory().keyboardShortcut(id: id, key: "A", modifiers: modifiers)
    let json: [String: AnyHashable] = [
      "id": id,
      "key": "A",
      "modifiers": modifiers.compactMap({ $0.rawValue })
    ]
    XCTAssertEqual(try KeyboardShortcut.decode(from: json),
                   subject)
  }
}
