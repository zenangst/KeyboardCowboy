@testable import ViewKit
import XCTest

class WorkflowListViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: WorkflowListView_Previews.self,
      size: CGSize(width: 300, height: 40)
    )
  }
}
