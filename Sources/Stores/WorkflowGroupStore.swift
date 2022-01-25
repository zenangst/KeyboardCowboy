import SwiftUI

final class WorkflowGroupStore: ObservableObject {
  @Published var groups = [WorkflowGroup]()
  @Published var selectedGroups = [WorkflowGroup]()

  @AppStorage("selectedGroupIds") private var selectedGroupIds = [String]()

  init(_ groups: [WorkflowGroup] = []) {
    _groups = .init(initialValue: groups)
  }

  func add(_ group: WorkflowGroup) {
    var modifiedGroups = self.groups
    modifiedGroups.append(group)
    groups = modifiedGroups
    selectedGroupIds = [group.id]
  }

  func add(_ workflow: Workflow) {
    var modifiedGroups = groups
    guard let firstGroupId = selectedGroupIds.first,
          let groupIndex = groups.firstIndex(where: { $0.id == firstGroupId }),
          var group = groups.first(where: { $0.id == firstGroupId }) else {
            return
          }

    group.workflows.append(workflow)
    modifiedGroups[groupIndex] = group

    groups = modifiedGroups
    selectedGroupIds = [group.id]
  }

  func receive(_ newGroups: [WorkflowGroup]) {
    let oldGroups = groups
    var modifiedGroups = groups
    for group in newGroups {
      guard let index = oldGroups.firstIndex(where: { $0.id == group.id }) else {
        continue
      }

      modifiedGroups[index] = group
    }

    groups = modifiedGroups
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
    selectedGroupIds.removeAll(where: { $0 == group.id })
  }

  func remove(_ workflow: Workflow) {
    guard let groupIndex = groups.firstIndex(where: {
      let ids = $0.workflows.compactMap({ $0.id })
      return ids.contains(workflow.id)
    }) else {
      return
    }

    var modifiedGroups = groups
    modifiedGroups[groupIndex].workflows.removeAll(where: { $0.id == workflow.id })
    groups = modifiedGroups
  }
}
