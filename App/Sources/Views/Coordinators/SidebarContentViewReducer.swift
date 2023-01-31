import Foundation

final class SidebarContentViewReducer {

  static func reduce(_ action: ContentView.Action, group: inout WorkflowGroup) {
    switch action {
    case .addWorkflow:
      let workflow = Workflow.empty()
      group.workflows.append(workflow)
    case .removeWorflows(let ids):
      group.workflows.removeAll(where: { ids.contains($0.id) })
    case .moveWorkflows(let source, let destination):
      group.workflows.move(fromOffsets: source, toOffset: destination)
    case .selectWorkflow:
      break
    }
  }
}
