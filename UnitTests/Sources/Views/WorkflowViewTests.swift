@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class WorkflowViewTests: XCTestCase {
  func testSnapshotPreviews() {
    let info = ProcessInfo.processInfo
    let version = "\(info.operatingSystemVersion.majorVersion).\(info.operatingSystemVersion.minorVersion)"
    assertSnapshot(
      matching: SnapshotWindow(WorkflowView_Previews.previews,
                               size: CGSize(width: 500, height: 400)).viewController,
      as: .image,
      named: "macOS\(version)")
  }
}
