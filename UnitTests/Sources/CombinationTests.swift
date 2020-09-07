@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class CombinationTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().combination().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "input": "⌃⌥A"
    ]
    XCTAssertEqual(try Combination.decode(from: json), ModelFactory().combination())
  }
}
