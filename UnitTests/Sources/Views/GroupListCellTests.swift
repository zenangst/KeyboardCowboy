@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class GroupListCellTests: XCTestCase {
  func testSnapshotPreviews() {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    assertSnapshot(
      matching: SnapshotWindow(GroupListCell_Previews.previews,
                               size: CGSize(width: 200, height: 40)).viewController,
      as: .image,
      named: "macOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
  }
}
