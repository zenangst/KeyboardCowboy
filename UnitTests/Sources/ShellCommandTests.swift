@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ScriptCommandTests: XCTestCase {
  enum ScriptCommandTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().scriptCommands()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw ScriptCommandTestError.unableToProduceString
    }
    assertSnapshot(matching: result, as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [[String: AnyHashable]] = [
      ["kind": ["appleScript": ["inline": "#!/usr/bin/env fish"]]],
      ["kind": ["appleScript": ["path": "file:///tmp/file"]]],
      ["kind": ["shell": ["inline": "#!/usr/bin/env fish"]]],
      ["kind": ["shell": ["path": "file:///tmp/file"]]]
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode([ScriptCommand].self, from: data)

    XCTAssertEqual(result, ModelFactory().scriptCommands())
  }
}
