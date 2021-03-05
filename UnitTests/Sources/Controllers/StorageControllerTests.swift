import LogicFramework
import XCTest
import ModelKit

class StorageControllerTests: XCTestCase {
  var tmpPath: String!

  override func setUp() {
    super.setUp()
    guard let tmpPath = ProcessInfo.processInfo.environment["TMPDIR"] else {
      XCTFail("Unable to find temp directory")
      return
    }
    self.tmpPath = tmpPath
  }

  func testStorageController() throws {
    let controller = ControllerFactory.shared.storageController(path: tmpPath)
    let groups = [
      Group(name: "A", color: "#000"),
      Group(name: "B", color: "#000"),
      Group(name: "C", color: "#000")
    ]

    XCTAssertNoThrow(try controller.save(groups))

    let savedGroups = try controller.load()

    XCTAssertEqual(savedGroups, groups)
  }
}
