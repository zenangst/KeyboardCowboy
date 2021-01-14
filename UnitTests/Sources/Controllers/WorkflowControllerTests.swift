@testable import LogicFramework
@testable import ModelKit
import XCTest

class WorkflowControllerTests: XCTestCase {
  func testWorkflowController() {
    let firstPass = [KeyboardShortcut(key: "1")]
    let secondPass = [KeyboardShortcut(key: "1"), KeyboardShortcut(key: "2")]
    let thirdPass = [KeyboardShortcut(key: "1"), KeyboardShortcut(key: "2"), KeyboardShortcut(key: "3")]

    let keyboardShortcutA = secondPass

    let keyboardShortcutB = thirdPass

    let keyboardShortcutC = [
      KeyboardShortcut(key: "1"),
      KeyboardShortcut(key: "3"),
      KeyboardShortcut(key: "2")
    ]

    let groups = [
      ModelFactory().group(
        name: "A", rule: Rule(), workflows: {
          [$0.workflow(keyboardShortcuts: { _ in keyboardShortcutA },
                        commands: { [.application($0.applicationCommand())] })]
        }),
      ModelFactory().group(
        name: "B", rule: Rule(), workflows: {
          [$0.workflow(keyboardShortcuts: { _ in keyboardShortcutB },
                       commands: { [.application($0.applicationCommand())] })]
        }),
      ModelFactory().group(
        name: "C", rule: Rule(), workflows: {
          [$0.workflow(keyboardShortcuts: { _ in keyboardShortcutC },
                       commands: { [.application($0.applicationCommand())] })]
        })
    ]

    let controller = WorkflowController()

    // Should match all workflows on the first pass because the command chain in `firstPass`
    // is shorter than the amount of commands. When that is the case, the algorithm simply
    // joins the combinations together and checks for `starts(with:)`.
    do {
      let workflows = controller.filterWorkflows(from: groups, keyboardShortcuts: firstPass)
      XCTAssertEqual(workflows.count, 3)
    }

    // On the second pass, `combinationC` should no longer be valid as it does no longer
    // match the combination sequence.
    do {
      let workflows = controller.filterWorkflows(from: groups, keyboardShortcuts: secondPass)
      XCTAssertEqual(workflows.count, 2)
    }

    // On the third go, we get a perfect match which means that only `combinationB`
    // should be returned after filtering is done.
    do {
      let workflows = controller.filterWorkflows(from: groups, keyboardShortcuts: thirdPass)
      XCTAssertEqual(workflows.count, 1)
    }
  }
}
