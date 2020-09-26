@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class OpenCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().openCommand(id: "foobar").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let subject = ModelFactory().openCommand()
    let json: [String: Any] = [
      "id": subject.id,
      "application": [
        "bundleName": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ],
      "path": "~/Desktop/new_real_final_draft_Copy_42.psd"
    ]
    XCTAssertEqual(try OpenCommand.decode(from: json), subject)
  }
}
