import Foundation

final class ContentViewActionReducer {
  static func reduce(_ action: ContentView.Action,
                     groupStore: GroupStore,
                     selectionPublisher: ContentSelectionIdsPublisher,
                     group: inout WorkflowGroup) async {
    switch action {
    case .moveWorkflowsToGroup(let groupId, let workflows):
      await groupStore.move(workflows, to: groupId)
      if let updatedGroup = await groupStore.group(withId: group.id) {
        group = updatedGroup
      }
    case .rerender:
      break
    case .addCommands(let workflowId, let commandIds):
      guard let index = group.workflows.firstIndex(where: { $0.id == workflowId }) else {
        return
      }
      var workflow = group.workflows[index]
      var commands = group.workflows.flatMap(\.commands)
        .filter({ commandIds.contains($0.id) })

      for (offset, _) in commands.enumerated() {
        commands[offset].id = UUID().uuidString
      }

      // We need to create copies of the commands.

      workflow.commands.append(contentsOf: commands)
      group.workflows[index] = workflow
    case .addWorkflow(let workflowId):
      let workflow = Workflow.empty(id: workflowId)
      group.workflows.append(workflow)
    case .removeWorflows(let ids):
      group.workflows.removeAll(where: { ids.contains($0.id) })
    case .moveWorkflows(let source, let destination):
      group.workflows.move(fromOffsets: source, toOffset: destination)
    case .selectWorkflow(let workflows, let groupIds):
      await selectionPublisher.publish(ContentSelectionIds(groupIds: groupIds, workflowIds: workflows))
    }
  }
}
