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
          "name": "Finder",
          "bundleIdentifier": "com.apple.Finder",
          "path": "/System/Library/CoreServices/Finder.app"
        ]],
        "days": [0, 1, 2, 3, 4, 5, 6]
      ],
      "workflows": [
        [
          "commands": [[
            "applicationCommand": [
              "application": ["name": "Finder",
                              "bundleIdentifier": "com.apple.Finder",
                              "path": "/System/Library/CoreServices/Finder.app"]
            ]
          ]],
          "combinations": [
            ["input": "⌃⌥A"]
          ],
          "name": "Open/active Finder"
        ]
      ]
    ]
    XCTAssertEqual(try Group.decode(from: json), ModelFactory().group())
  }
}
