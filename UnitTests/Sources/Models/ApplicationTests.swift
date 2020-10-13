@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class ApplicationTests: XCTestCase {
  func testJSONEncoding() throws {
    assertSnapshot(matching: try ModelFactory.application(id: "foo").toString(), as: .dump)
  }

  func testJSONDecoding() throws {
    let json = [
      "id": "foo",
      "bundleName": "Finder",
      "bundleIdentifier": "com.apple.Finder",
      "path": "/System/Library/CoreServices/Finder.app"
    ]
    XCTAssertEqual(try Application.decode(from: json), ModelFactory.application(id: "foo"))
  }
}
