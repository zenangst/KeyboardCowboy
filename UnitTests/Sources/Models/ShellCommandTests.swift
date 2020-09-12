@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ScriptCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().scriptCommands().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [[String: AnyHashable]] = [
      ["appleScript": ["inline": "#!/usr/bin/env fish"]],
      ["appleScript": ["path": "/tmp/file"]],
      ["shell": ["inline": "#!/usr/bin/env fish"]],
      ["shell": ["path": "/tmp/file"]]
    ]
    XCTAssertEqual(try [ScriptCommand].decode(from: json), ModelFactory().scriptCommands())
  }
}
