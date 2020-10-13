@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class DayTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().days().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [0, 1, 2, 3, 4, 5, 6]
    XCTAssertEqual(try [Rule.Day].decode(from: json), ModelFactory().days())
  }
}
