@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupTests: XCTestCase {
  enum GroupError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().group().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: Any] = [
      "name": "Global shortcuts",
      "rules": [
        ["application": [
          "name": "Finder",
          "bundleIdentifier": "com.apple.Finder",
          "path": "/System/Library/CoreServices/Finder.app"
        ]],
       ["days": [0, 1, 2, 3, 4, 5, 6]]
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
          "name": "Open/active Finder"
        ]
      ]
    ]
    XCTAssertEqual(try Group.decode(from: json), ModelFactory().group())
  }
}
