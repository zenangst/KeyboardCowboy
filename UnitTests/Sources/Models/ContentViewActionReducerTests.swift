@testable import Keyboard_Cowboy
import XCTest

@MainActor
final class ContentViewActionReducerTests: XCTestCase {
  func testReduceContentViewAction_noop() {
    let id = UUID().uuidString
    let ctx = context()
    var subject = subject(id)

    // Nothing should happen because `.rerender` is no-op.
    ContentViewActionReducer.reduce(.rerender([id]), groupStore: ctx.store,
                                    selectionManager: ctx.selector,
                                    group: &subject.original)

    XCTAssertEqual(subject.original, subject.copy)

    // Nothing should happen because `.selectWorkflow` is no-op.
    ContentViewActionReducer.reduce(.selectWorkflow(workflowIds: [], groupIds: []), groupStore: ctx.store,
                                    selectionManager: ctx.selector,
                                    group: &subject.original)

    XCTAssertEqual(subject.original, subject.copy)
  }

  func testReduceContentViewAction_moveWorkflowsToGroup() {
    let ctx = context([
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: [])
    ])
    let action: ContentView.Action = .moveWorkflowsToGroup("group-2-id",
                                                           workflows: ["workflow-1-id", "workflow-2-id"])
    var subject = ctx.store.groups[0]

    ContentViewActionReducer.reduce(action, groupStore: ctx.store,
                                    selectionManager: ctx.selector,
                                    group: &subject)

    // Verify that the workflows were moved to the new group.
    XCTAssertTrue(ctx.store.groups[0].workflows.isEmpty)
    XCTAssertEqual(ctx.store.groups[1].workflows.map(\.id).sorted(), [
      "workflow-1-id", "workflow-2-id"
    ])
  }

  // MARK: Private methods

  private func subject(_ id: String) -> (original: WorkflowGroup, copy: WorkflowGroup) {
    let group = WorkflowGroup.empty(id: id)
    return (original: group, copy: group)
  }

  private func context(_ groups: [WorkflowGroup] = []) -> (store: GroupStore,
                                                           selector: SelectionManager<ContentViewModel>) {
    (store: GroupStore(groups), selector: SelectionManager())
  }
}

private struct GroupSelection: Identifiable, Hashable {
  let id: String
}
