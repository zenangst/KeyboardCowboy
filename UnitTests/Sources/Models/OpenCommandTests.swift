@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class OpenCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().openCommand().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json: [String: AnyHashable] = [
      "application": [
        "name": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "url": "/System/Library/CoreServices/Finder.app"
      ],
      "url": "~/Desktop/new_real_final_draft_Copy_42.psd"
    ]
    XCTAssertEqual(try OpenCommand.decode(from: json), ModelFactory().openCommand())
  }
}
