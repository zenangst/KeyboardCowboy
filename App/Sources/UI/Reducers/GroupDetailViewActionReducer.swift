import Foundation

final class GroupDetailViewActionReducer {
  @MainActor
  static func reduce(_ action: GroupDetailView.Action,
                     groupStore: GroupStore,
                     selectionManager: SelectionManager<GroupDetailViewModel>,
                     group: inout WorkflowGroup) {
    switch action {
    case .refresh, .selectWorkflow:
      break
    case .duplicate(let workflowIds):
      var newIds = Set<Workflow.ID>()
      for workflowId in workflowIds {
        guard let workflow = groupStore.workflow(withId: workflowId) else { continue }
        let workflowCopy = workflow.copy()

        if let index = group.workflows.firstIndex(where: { $0.id == workflowId }) {
          group.workflows.insert(workflowCopy, at: index)
        } else {
          group.workflows.append(workflowCopy)
        }

        newIds.insert(workflowCopy.id)
      }
      selectionManager.publish(newIds)
    case .moveWorkflowsToGroup(let groupId, let workflows):
      groupStore.move(workflows, to: groupId)
      if let updatedGroup = groupStore.group(withId: group.id) {
        group = updatedGroup
      }
    case .moveCommandsToWorkflow(let toWorkflow, let fromWorkflow, let commandIds):
      guard let oldIndex = group.workflows.firstIndex(where: { $0.id == fromWorkflow }),
            let newIndex = group.workflows.firstIndex(where: { $0.id == toWorkflow  }) else {
        return
      }

      var oldWorkflow = group.workflows[oldIndex]
      var newWorkflow = group.workflows[newIndex]

      let commands = oldWorkflow.commands
        .filter({ commandIds.contains($0.id) })
      oldWorkflow.commands.removeAll(where: { commandIds.contains($0.id) })
      newWorkflow.commands.append(contentsOf: commands)


      group.workflows[oldIndex] = oldWorkflow
      group.workflows[newIndex] = newWorkflow
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
