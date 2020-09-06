import Foundation
@testable import LogicFramework
import XCTest

class WorkflowTests: XCTestCase {
  enum WorkflowError: Error {
    case unableToProduceString
  }

  func testJSONEncoding() throws {
    let subject = ModelFactory().workflow()
    let data = try JSONEncoder().encode(subject)
    guard let result = String(data: data, encoding: .utf8) else {
      throw WorkflowError.unableToProduceString
    }
    let expected = "{\"commands\":[{\"applicationCommand\":{\"application\":{\"name\":\"Finder\",\"bundleIdentifier\":\"com.apple.Finder\",\"path\":\"/System/Library/CoreServices/Finder.app\"}}}],\"name\":\"Open/active Finder\"}"

    XCTAssertEqual(result.replacingOccurrences(of: "\\", with: ""), expected)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "commands": [[
        "applicationCommand": [
          "application": ["name": "Finder", "bundleIdentifier": "com.apple.Finder", "path": "/System/Library/CoreServices/Finder.app"]
        ]
      ]],
      "name": "Open/active Finder"
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let result = try JSONDecoder().decode(Workflow.self, from: data)

    XCTAssertEqual(result, ModelFactory().workflow())
  }
}
