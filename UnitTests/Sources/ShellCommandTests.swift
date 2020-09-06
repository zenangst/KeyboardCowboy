@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ScriptCommandTests: XCTestCase {
  enum ScriptCommandTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().scriptCommands().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [[String: AnyHashable]] = [
      ["kind": ["appleScript": ["inline": "#!/usr/bin/env fish"]]],
      ["kind": ["appleScript": ["path": "file:///tmp/file"]]],
      ["kind": ["shell": ["inline": "#!/usr/bin/env fish"]]],
      ["kind": ["shell": ["path": "file:///tmp/file"]]]
    ]
    XCTAssertEqual(try [ScriptCommand].decode(from: json), ModelFactory().scriptCommands())
  }
}
