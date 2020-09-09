@testable import LogicFramework
import XCTest

class WorkflowControllerTests: XCTestCase {
  func testWorkflowController() {
    let firstPass = [Combination(input: "1")]
    let secondPass = [Combination(input: "1"), Combination(input: "2")]
    let thirdPass = [Combination(input: "1"), Combination(input: "2"), Combination(input: "3")]

    let combinationA = secondPass

    let combinationB = thirdPass

    let combinationC = [
      Combination(input: "1"),
      Combination(input: "3"),
      Combination(input: "2")
    ]

    // TODO: Improve this test by splitting the rules into seperated groups.
    let groups = [
      ModelFactory().group(
        name: "A", rule: Rule(), workflows: {
          [
            $0.workflow(combinations: { _ in combinationA },
                        commands: { [.application($0.applicationCommand())] }),
            $0.workflow(combinations: { _ in combinationB },
                        commands: { [.application($0.applicationCommand())] }),
            $0.workflow(combinations: { _ in combinationC },
                        commands: { [.application($0.applicationCommand())] })
          ]
        })
    ]

    let controller = WorkflowController()

    // Should match all workflows on the first pass because the command chain in `firstPass`
    // is shorter than the amount of commands. When that is the case, the algorithm simply
    // joins the combinations together and checks for `starts(with:)`.
    do {
      let workflows = controller.filterWorkflows(from: groups, combinations: firstPass)
      XCTAssertEqual(workflows.count, 3)
    }

    // On the second pass, `combinationC` should no longer be valid as it does no longer
    // match the combination sequence.
    do {
      let workflows = controller.filterWorkflows(from: groups, combinations: secondPass)
      XCTAssertEqual(workflows.count, 2)
    }

    // On the third go, we get a perfect match which means that only `combinationB`
    // should be returned after filtering is done.
    do {
      let workflows = controller.filterWorkflows(from: groups, combinations: thirdPass)
      XCTAssertEqual(workflows.count, 1)
    }
  }
}
