@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupTests: XCTestCase {
  enum GroupError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().group()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw GroupError.unableToProduceString
    }
    assertSnapshot(matching: result, as: .dump)
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
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(Group.self, from: data)

    XCTAssertEqual(result, ModelFactory().group())
  }
}
