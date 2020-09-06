@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class DayTests: XCTestCase {
  enum DayTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().days()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw DayTestError.unableToProduceString
    }
    assertSnapshot(matching: result, as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [0, 1, 2, 3, 4, 5, 6]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode([Rule.Day].self, from: data)

    XCTAssertEqual(result, ModelFactory().days())
  }
}
