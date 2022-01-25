import Foundation

final class WorkflowGroupStore: ObservableObject {
  @Published var groups = [WorkflowGroup]()

  init(_ groups: [WorkflowGroup] = []) {
    _groups = .init(initialValue: groups)
  }

  func receive(_ newWorkflows: [Workflow]) {
    var newGroups = groups
    for newWorkflow in newWorkflows {
      guard let group = newGroups.first(where: { group in
        let workflowIds = group.workflows.compactMap({ $0.id })
        return workflowIds.contains(newWorkflow.id)
      })
      else { continue }

      guard let groupIndex = newGroups.firstIndex(of: group) else { continue }

      guard let workflowIndex = group.workflows.firstIndex(where: { $0.id == newWorkflow.id })
      else { continue }

      let oldWorkflow = groups[groupIndex].workflows[workflowIndex]
      if oldWorkflow == newWorkflow {
        continue
      }

      newGroups[groupIndex].workflows[workflowIndex] = newWorkflow
    }

    groups = newGroups
  }

  func remove(_ group: WorkflowGroup) {
    groups.removeAll(where: { $0.id == group.id })
  }
}
