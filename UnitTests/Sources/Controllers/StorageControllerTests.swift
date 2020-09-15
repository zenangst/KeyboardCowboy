import LogicFramework
import XCTest

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
    let controller = ControllerFactory().storageController(path: tmpPath)
    let groups = [
      Group(name: "A"),
      Group(name: "B"),
      Group(name: "C")
    ]

    XCTAssertNoThrow(try controller.save(groups))

    let savedGroups = try controller.load()

    XCTAssertEqual(savedGroups, groups)
  }
}
