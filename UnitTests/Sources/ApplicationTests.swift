import Foundation
@testable import LogicFramework
import XCTest

class ApplicationTests: XCTestCase {
  enum ApplicationTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().application()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw ApplicationTestError.unableToProduceString
    }
    let expected = "{\"name\":\"Finder\",\"bundleIdentifier\":\"com.apple.Finder\",\"path\":\"/System/Library/CoreServices/Finder.app\"}"

    XCTAssertEqual(result.replacingOccurrences(of: "\\", with: ""), expected)
  }

  func testJSONDecoding() throws {
    let json = [
      "name": "Finder",
      "bundleIdentifier": "com.apple.Finder",
      "path": "/System/Library/CoreServices/Finder.app"
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(Application.self, from: data)

    XCTAssertEqual(result, ModelFactory().application())
  }
}
