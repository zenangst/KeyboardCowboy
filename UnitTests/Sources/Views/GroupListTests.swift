@testable import ViewKit
import Cocoa
import SwiftUI
import Foundation
import SnapshotTesting
import XCTest

class GroupListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertSnapshot(
      matching: SnapshotWindow(GroupList_Previews.previews,
                               size: CGSize(width: GroupList.idealWidth, height: 400)).viewController,
      as: .image)
  }
}
