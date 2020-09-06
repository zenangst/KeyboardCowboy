@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class RuleTests: XCTestCase {
  enum RuleTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().rules()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw RuleTestError.unableToProduceString
    }
    assertSnapshot(matching: result, as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [[String: AnyHashable]] = [
      ["application": [
        "name": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]],
     ["days": [0, 1, 2, 3, 4, 5, 6]]
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode([Rule].self, from: data)

    XCTAssertEqual(result, ModelFactory().rules())
  }
}
