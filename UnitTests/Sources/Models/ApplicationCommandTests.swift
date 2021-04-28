@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class ApplicationCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    let result = ModelFactory().applicationCommand(id: "foobar")
    assertSnapshot(matching: try result.toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let subject = ModelFactory().applicationCommand()
    let json: [String: Any] = [
      "id": subject.id,
      "application": [
        "id": subject.application.id,
        "bundleName": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]
    ]
    XCTAssertEqual(try ApplicationCommand.decode(from: json), subject)
  }
}
