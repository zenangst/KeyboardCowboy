@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class WorkflowTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().workflow().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: Any] = [
      "commands": [[
        "applicationCommand": [
          "application": ["bundleName": "Finder",
                          "bundleIdentifier": "com.apple.Finder",
                          "path": "/System/Library/CoreServices/Finder.app"]
        ]
      ]],
      "keyboardShortcuts": [
        [
          "key": "A",
          "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]
        ]
      ],
      "name": "Open/active Finder"
    ]
    XCTAssertEqual(try Workflow.decode(from: json), ModelFactory().workflow())
  }
}
