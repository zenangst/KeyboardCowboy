import Foundation

final class ContentViewActionReducer {
  static func reduce(_ action: ContentView.Action,
                     selectionPublisher: ContentSelectionIdsPublisher,
                     group: inout WorkflowGroup) async {
    switch action {
    case .addWorkflow:
      let workflow = Workflow.empty()
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
