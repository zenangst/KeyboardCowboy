import Foundation
@testable import LogicFramework
import XCTest

class OpenCommandTests: XCTestCase {
  enum OpenCommandTestError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().openCommand()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw OpenCommandTestError.unableToProduceString
    }
    let expected = "{\"application\":{\"name\":\"Finder\",\"bundleIdentifier\":\"com.apple.Finder\",\"path\":\"/System/Library/CoreServices/Finder.app\"},\"url\":\"~/Desktop/new_real_final_draft_Copy_42.psd\"}"

    XCTAssertEqual(result.replacingOccurrences(of: "\\", with: ""), expected)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "application": [
        "name": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ],
      "url": "~/Desktop/new_real_final_draft_Copy_42.psd"
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(OpenCommand.self, from: data)

    XCTAssertEqual(result, ModelFactory().openCommand())
  }
}
