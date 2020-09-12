@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ApplicationCommandTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory().applicationCommand().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [
      "application": [
        "bundleName": "Finder",
        "bundleIdentifier": "com.apple.Finder",
        "path": "/System/Library/CoreServices/Finder.app"
      ]
    ]
    XCTAssertEqual(try ApplicationCommand.decode(from: json), ModelFactory().applicationCommand())
  }
}
