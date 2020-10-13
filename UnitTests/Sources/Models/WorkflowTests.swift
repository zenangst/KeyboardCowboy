@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class WorkflowTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().workflow(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let subject = ModelFactory().workflow(id: UUID().uuidString)
    let json: [String: Any] = [
      "id": subject.id,
      "commands": [[
        "applicationCommand": [
          "id": subject.id,
          "application": [
            "id": subject.id,
            "bundleName": "Finder",
            "bundleIdentifier": "com.apple.Finder",
            "path": "/System/Library/CoreServices/Finder.app"]
        ]
      ]],
      "keyboardShortcuts": [
        [
          "id": subject.id,
          "key": "A",
          "modifiers": [ModifierKey.control.rawValue, ModifierKey.option.rawValue]
        ]
      ],
      "name": "Open/active Finder"
    ]
    XCTAssertEqual(try Workflow.decode(from: json), subject)
  }
}
