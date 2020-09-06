@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class KeyboardCommandTests: XCTestCase {
  enum KeyboardCommandTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().keyboardCommand()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw KeyboardCommandTestError.unableToProduceString
    }
    assertSnapshot(matching: result, as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [
      "output": "A"
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(KeyboardCommand.self, from: data)

    XCTAssertEqual(result, ModelFactory().keyboardCommand())
  }
}
