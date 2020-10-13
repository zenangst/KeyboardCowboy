@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class GroupTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().group(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let id = UUID().uuidString
    let subject = ModelFactory().group(
      id: id,
      rule: Rule(
        id: id,
        bundleIdentifiers: ["com.apple.Finder"],
        days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday])) { _ in
      return [
        Workflow(id: id, name: "Open/activate Finder", keyboardShortcuts: [
          KeyboardShortcut(id: id, key: "A", modifiers: [.control, .option])
        ], commands: [
          .application(.init(id: id, application: Application.finder(id: id)))
        ])
      ]
    }
    let json: [String: Any] = [
      "id": subject.id,
      "name": "Global shortcuts",
      "color": subject.color,
      "rule": [
        "id": subject.id,
        "bundleIdentifiers": ["com.apple.Finder"],
        "days": [0, 1, 2, 3, 4, 5, 6]
      ],
      "workflows": [
        [
          "id": subject.id,
          "commands": [[
            "applicationCommand": [
              "id": subject.id,
              "application": [
                "id": subject.id,
                "bundleName": "Finder",
                "bundleIdentifier": "com.apple.finder",
                "path": "/System/Library/CoreServices/Finder.app"]
            ]
          ]],
          "keyboardShortcuts": [
            ["id": subject.id, "key": "A", "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]]
          ],
          "name": "Open/activate Finder"
        ]
      ]
    ]
    XCTAssertEqual(try Group.decode(from: json), subject)
  }
}
