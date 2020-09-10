@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class GroupListCellTests: XCTestCase {
  func testSnapshotPreviews() {
    let info = ProcessInfo.processInfo
    let version = "\(info.operatingSystemVersion.majorVersion).\(info.operatingSystemVersion.minorVersion)"
    assertSnapshot(
      matching: SnapshotWindow(GroupListCell_Previews.previews,
                               size: CGSize(width: 200, height: 40)).viewController,
      as: .image,
      named: "macOS\(version)")
  }
}
