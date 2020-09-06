@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class WorkflowTests: XCTestCase {
  enum WorkflowError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().workflow().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "commands": [[
        "applicationCommand": [
          "application": ["name": "Finder",
                          "bundleIdentifier": "com.apple.Finder",
                          "path": "/System/Library/CoreServices/Finder.app"]
        ]
      ]],
      "name": "Open/active Finder"
    ]
    XCTAssertEqual(try Workflow.decode(from: json), ModelFactory().workflow())
  }
}
