@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ScriptCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().scriptCommands(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let id = UUID().uuidString
    let subject = ModelFactory().scriptCommands(id: id)
    let json: [[String: AnyHashable]] = [
      ["id": id, "appleScript": ["inline": "#!/usr/bin/env fish"]],
      ["id": id, "appleScript": ["path": "/tmp/file"]],
      ["id": id, "shell": ["inline": "#!/usr/bin/env fish"]],
      ["id": id, "shell": ["path": "/tmp/file"]]
    ]
    XCTAssertEqual(try [ScriptCommand].decode(from: json), subject)
  }
}
