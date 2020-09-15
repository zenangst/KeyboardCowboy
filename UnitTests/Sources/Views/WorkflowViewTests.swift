@testable import ViewKit
import XCTest

class WorkflowViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(from: WorkflowView_Previews.self, size: CGSize(width: 500, height: 400))
  }
}
