@testable import ViewKit
import XCTest

class WorkflowListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: WorkflowList_Previews.self,
      size: CGSize(width: 300, height: 400)
    )
  }
}
