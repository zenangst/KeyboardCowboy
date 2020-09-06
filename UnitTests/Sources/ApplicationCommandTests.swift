import Foundation
@testable import LogicFramework
import XCTest

class ApplicationCommandTests: XCTestCase {
  enum ApplicationCommandTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().applicationCommand()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw ApplicationCommandTestError.unableToProduceString
    }
    let expected = "{\"application\":{\"name\":\"Finder\",\"bundleIdentifier\":\"com.apple.Finder\",\"path\":\"/System/Library/CoreServices/Finder.app\"}}"

    XCTAssertEqual(result.replacingOccurrences(of: "\\", with: ""), expected)
  }

  func testJSONDecoding() throws {
    let json = [
      "application": [
        "name": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(ApplicationCommand.self, from: data)

    XCTAssertEqual(result, ModelFactory().applicationCommand())
  }
}
