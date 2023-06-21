import Foundation

final class ContentViewActionReducer {
  @MainActor
  static func reduce(_ action: ContentView.Action,
                     groupStore: GroupStore,
                     selectionManager: SelectionManager<ContentViewModel>,
                     group: inout WorkflowGroup) {
    switch action {
    case .refresh, .selectWorkflow:
      break
    case .moveWorkflowsToGroup(let groupId, let workflows):
      groupStore.move(workflows, to: groupId)
      if let updatedGroup = groupStore.group(withId: group.id) {
        group = updatedGroup
      }
    case .addWorkflow(let workflowId):
      let workflow = Workflow.empty(id: workflowId)
      group.workflows.append(workflow)
    case .removeWorkflows(let ids):
      var newIndex = 0
      for (index, group) in group.workflows.enumerated() {
        if ids.contains(group.id) { newIndex = index }
      }

      group.workflows.removeAll(where: { ids.contains($0.id) })

      if group.workflows.isEmpty {
        selectionManager.publish([])
      } else {
        if newIndex >= group.workflows.count {
          newIndex = max(group.workflows.count - 1, 0)
        }
        selectionManager.publish([group.workflows[newIndex].id])
      }
    case .reorderWorkflows(let source, let destination):
      group.workflows.move(fromOffsets: source, toOffset: destination)
    }
  }
}
