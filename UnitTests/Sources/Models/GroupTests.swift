@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().group(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let id = UUID().uuidString
    let subject = ModelFactory().group(id: id)
    let json: [String: Any] = [
      "id": subject.id,
      "name": "Global shortcuts",
      "color": subject.color,
      "rule": [
        "bundleIdentifiers": ["com.apple.Finder"],
        "days": [0, 1, 2, 3, 4, 5, 6]
      ],
      "workflows": [
        [
          "id": subject.id,
          "commands": [[
            "applicationCommand": [
              "id": subject.id,
              "application": ["bundleName": "Finder",
                              "bundleIdentifier": "com.apple.Finder",
                              "path": "/System/Library/CoreServices/Finder.app"]
            ]
          ]],
          "keyboardShortcuts": [
            ["id": subject.id, "key": "A", "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]]
          ],
          "name": "Open/active Finder"
        ]
      ]
    ]
    XCTAssertEqual(try Group.decode(from: json), subject)
  }
}
