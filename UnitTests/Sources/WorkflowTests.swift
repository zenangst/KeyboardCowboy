@testable import LogicFramework
import Foundation
import SnapshotTesting
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
    assertSnapshot(matching: result, as: .dump)
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
