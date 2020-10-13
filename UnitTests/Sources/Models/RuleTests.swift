@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class RuleTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().rule(id: "42").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let id = UUID().uuidString
    let json: [String: AnyHashable] = [
      "id": id,
      "bundleIdentifiers": ["com.apple.Finder"],
      "days": [0, 1, 2, 3, 4, 5, 6]
    ]
    XCTAssertEqual(try Rule.decode(from: json), ModelFactory().rule(id: id))
  }
}
