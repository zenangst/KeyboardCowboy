@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().group().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: Any] = [
      "name": "Global shortcuts",
      "rule": [
        "applications": [[
          "bundleName": "Finder",
          "bundleIdentifier": "com.apple.Finder",
          "path": "/System/Library/CoreServices/Finder.app"
        ]],
        "days": [0, 1, 2, 3, 4, 5, 6]
      ],
      "workflows": [
        [
          "commands": [[
            "applicationCommand": [
              "application": ["bundleName": "Finder",
                              "bundleIdentifier": "com.apple.Finder",
                              "path": "/System/Library/CoreServices/Finder.app"]
            ]
          ]],
          "keyboardShortcuts": [
            ["key": "A", "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]]
          ],
          "name": "Open/active Finder"
        ]
      ]
    ]
    XCTAssertEqual(try Group.decode(from: json), ModelFactory().group())
  }
}
