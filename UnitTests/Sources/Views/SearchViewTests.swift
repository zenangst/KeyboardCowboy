@testable import ViewKit
import XCTest

class SearchViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: SearchView_Previews.self,
      size: CGSize(width: 640, height: 720)
    )
  }
}
