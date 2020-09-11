@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class ApplicationTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory.application().toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [
      "name": "Finder",
      "bundleIdentifier": "com.apple.Finder",
      "url": "/System/Library/CoreServices/Finder.app"
    ]
    XCTAssertEqual(try Application.decode(from: json), ModelFactory.application())
  }
}
