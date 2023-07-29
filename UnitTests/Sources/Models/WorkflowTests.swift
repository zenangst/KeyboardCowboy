@testable import Keyboard_Cowboy
import XCTest

final class WorkflowTests: XCTestCase {
  func testCopy() {
    let subject = Workflow.designTime(.application([.init(application: .calendar())]))
    let copy = subject.copy()

    XCTAssertNotEqual(subject.id, copy.id)
    XCTAssertEqual(subject.name + " copy", copy.name)
    XCTAssertEqual(subject.isEnabled, copy.isEnabled)

    switch (subject.trigger, copy.trigger) {
    case (.application(let lhs), .application(let rhs)):
      XCTAssertEqual(lhs.count, rhs.count)
      for x in 0..<lhs.count {
        XCTAssertNotEqual(lhs[x].id, rhs[x].id)
        XCTAssertEqual(lhs[x].contexts, rhs[x].contexts)
        XCTAssertEqual(lhs[x].application, rhs[x].application)
      }
    default:
      XCTFail("Wrong case!")
    }

    XCTAssertEqual(subject.execution, copy.execution)

    for x in 0..<subject.commands.count {
      XCTAssertNotEqual(subject.commands[x].id, copy.commands[x].id)
      XCTAssertEqual(subject.commands[x].name, copy.commands[x].name)
    }
  }
}
