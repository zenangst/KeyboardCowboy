@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ApplicationCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().applicationCommand(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let subject = ModelFactory().applicationCommand()
    let json: [String: Any] = [
      "id": subject.id,
      "application": [
        "bundleName": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]
    ]
    XCTAssertEqual(try ApplicationCommand.decode(from: json), subject)
  }
}
