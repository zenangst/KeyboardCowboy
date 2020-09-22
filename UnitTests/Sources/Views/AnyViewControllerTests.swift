@testable import ViewKit
import XCTest
import Combine

class AnyViewControllerTests: XCTestCase {
  private var controller: AnyViewController<Folder, FolderAction>!
  private var cancellables = Set<AnyCancellable>()

  override func setUp() {
    super.setUp()
    controller = TestController().erase()
  }

  func testPerform() {
    XCTAssertTrue(controller.name.isEmpty)
    controller.perform(.rename("test"))
    XCTAssertEqual(controller.name, "test")
  }

  func testAction() {
    let action = controller.action(.rename("test"))
    XCTAssertTrue(controller.name.isEmpty)
    action()
    XCTAssertEqual(controller.name, "test")
  }

  func testBind() {
    XCTAssertTrue(controller.name.isEmpty)

    let binding = controller.bind(\.name, { .rename($0) })
    binding.wrappedValue = "test"
    XCTAssertEqual(binding.wrappedValue, "test")
    XCTAssertEqual(controller.name, "test")
  }
}

// MARK: - Helpers

private final class TestController: ViewController {
  @Published var state = Folder(name: "")

  func perform(_ action: FolderAction) {
    switch action {
    case .rename(let string):
      state.name = string
    }
  }
}

private struct Folder {
  var name: String
}

private enum FolderAction {
  case rename(String)
}
