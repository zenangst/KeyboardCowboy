@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class KeyboardCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().keyboardCommand(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let id = UUID().uuidString
    let subject = ModelFactory().keyboardCommand(id: id)
    let json: [String: Any] = [
      "id": subject.id,
      "keyboardShortcut": ["id": subject.id, "key": "A"]
    ]
    XCTAssertEqual(try KeyboardCommand.decode(from: json), subject)
  }
}
