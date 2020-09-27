@testable import ViewKit
import XCTest

class MainViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: MainView_Previews.self,
      size: CGSize(width: 960, height: 480)
    )
  }
}
