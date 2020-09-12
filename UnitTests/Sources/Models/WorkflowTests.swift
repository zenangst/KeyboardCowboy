@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class WorkflowTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().workflow().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "commands": [[
        "applicationCommand": [
          "application": ["bundleName": "Finder",
                          "bundleIdentifier": "com.apple.Finder",
                          "path": "/System/Library/CoreServices/Finder.app"]
        ]
      ]],
      "combinations": [
        ["input": "⌃⌥A"]
      ],
      "name": "Open/active Finder"
    ]
    XCTAssertEqual(try Workflow.decode(from: json), ModelFactory().workflow())
  }
}
