import SwiftUI

final class GroupStore: ObservableObject {
  private static var appStorage: AppStorageStore = .init()
  @Published var groups = [WorkflowGroup]()
  @Published var selectedGroups = [WorkflowGroup]()
  @Published var selectedGroupIds: [String]

  init(_ groups: [WorkflowGroup] = []) {
    _selectedGroupIds = .init(initialValue: Array(Self.appStorage.groupIds))
    _groups = .init(initialValue: groups)
    _selectedGroups = .init(initialValue: groups.filter { selectedGroupIds.contains($0.id) })
  }

  func group(withId id: String) -> WorkflowGroup? {
    groups.first { $0.id == id }
  }

  func add(_ group: WorkflowGroup) {
    var modifiedGroups = self.groups
    modifiedGroups.append(group)
    groups = modifiedGroups
    selectedGroupIds = [group.id]
    selectedGroups = [group]
  }

  func add(_ workflow: Workflow) {
    guard var group = selectedGroups.first,
          let groupIndex = groups.firstIndex(of: group) else { return }

    var modifiedGroups = groups

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

  func move(source: IndexSet, destination: Int) {
    groups.move(fromOffsets: source, toOffset: destination)
  }

  func updateGroups(_ groups: [WorkflowGroup]) {
    let oldGroups = self.groups
    var newGroups = self.groups
    for group in groups {
      guard let index = oldGroups.firstIndex(where: { $0.id == group.id }) else { return }
      newGroups[index] = group
    }
    self.groups = newGroups
  }

  func receive(_ newWorkflows: [Workflow]) -> [WorkflowGroup] {
    let newGroups = updateGroups(with: newWorkflows)
    groups = newGroups
    return newGroups
  }

  func remove(_ groups: [WorkflowGroup]) {
    for group in groups {
      remove(group)
    }
  }

  func removeGroups(with ids: [WorkflowGroup.ID]) {
    groups.removeAll(where: { ids.contains($0.id) })
    selectedGroupIds.removeAll(where: { ids.contains($0) })
  }

  func remove(_ group: WorkflowGroup) {
    groups.removeAll(where: { $0.id == group.id })
    selectedGroupIds.removeAll(where: { $0 == group.id })
  }

  func remove(_ workflows: [Workflow]) {
    for workflow in workflows {
      remove(workflow)
    }
  }

  func workflow(withId id: Workflow.ID) -> Workflow? {
    groups
      .flatMap(\.workflows)
      .first(where: { $0.id == id })
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

  // MARK: Private methods

  private func updateGroups(with newWorkflows: [Workflow]) -> [WorkflowGroup] {
    // Fix bug when trying to reorder group.
    var newGroups = groups
    for newWorkflow in newWorkflows {
      guard let group = newGroups.first(where: { group in
        let workflowIds = group.workflows.compactMap({ $0.id })
        return workflowIds.contains(newWorkflow.id)
      })
      else { continue }

      guard let groupIndex = newGroups.firstIndex(of: group) else { continue }

      guard let workflowIndex = group.workflows.firstIndex(where: { $0.id == newWorkflow.id })
      else {
        newGroups[groupIndex].workflows.append(newWorkflow)
        continue
      }

      let oldWorkflow = groups[groupIndex].workflows[workflowIndex]
      if oldWorkflow == newWorkflow {
        continue
      }

      newGroups[groupIndex].workflows[workflowIndex] = newWorkflow
    }
    return newGroups
  }
}
