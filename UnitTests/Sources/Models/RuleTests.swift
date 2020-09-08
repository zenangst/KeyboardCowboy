@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class RuleTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().rule().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "applications": [[
        "name": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]],
      "days": [0, 1, 2, 3, 4, 5, 6]
    ]
    XCTAssertEqual(try Rule.decode(from: json), ModelFactory().rule())
  }
}
