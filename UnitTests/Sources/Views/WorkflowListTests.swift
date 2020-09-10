@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class WorkflowListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertSnapshot(
      matching: SnapshotWindow(WorkflowList_Previews.previews,
                               size: CGSize(width: 200, height: 400)).viewController,
      as: .image,
      named: "macOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
  }
}
