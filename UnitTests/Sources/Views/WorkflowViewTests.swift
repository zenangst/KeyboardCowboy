@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class WorkflowViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertSnapshot(
      matching: SnapshotWindow(WorkflowView_Previews.previews,
                               size: CGSize(width: 500, height: 400)).viewController,
      as: .image,
      named: "macOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
  }
}
