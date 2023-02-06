import SwiftUI

final class GroupStore: ObservableObject {
  private static var appStorage: AppStorageStore = .init()
  @MainActor
  @Published var groups = [WorkflowGroup]()

  init(_ groups: [WorkflowGroup] = []) {
    _groups = .init(initialValue: groups)
  }

  @MainActor
  func group(withId id: String) -> WorkflowGroup? {
    groups.first { $0.id == id }
  }

  @MainActor
  func add(_ group: WorkflowGroup) {
    var newGroups = groups
    newGroups.append(group)
    updateGroups(newGroups)
  }

  @MainActor
  func move(source: IndexSet, destination: Int) {
    var newGroups = groups
    newGroups.move(fromOffsets: source, toOffset: destination)
    updateGroups(newGroups)
  }

  @MainActor
  func updateGroups(_ groups: [WorkflowGroup]) {
    let oldGroups = self.groups
    var newGroups = oldGroups
    for group in groups {
      guard let index = oldGroups.firstIndex(where: { $0.id == group.id }) else { return }
      newGroups[index] = group
    }
    commitGroups(newGroups)
  }

  @MainActor
  func removeGroups(with ids: [WorkflowGroup.ID]) {
    var newGroups = groups
    newGroups.removeAll(where: { ids.contains($0.id) })
    updateGroups(newGroups)
  }

  @MainActor
  func workflow(withId id: Workflow.ID) -> Workflow? {
    groups
      .flatMap(\.workflows)
      .first(where: { $0.id == id })
  }

  @MainActor
  func command(withId id: Command.ID, workflowId: Workflow.ID) -> Command? {
    workflow(withId: workflowId)?
      .commands
      .first(where: { $0.id == id })
  }

  @discardableResult
  func commit(_ newWorkflows: [Workflow]) async -> [WorkflowGroup] {
    let newGroups = await updateOrAddWorkflows(with: newWorkflows)
    await commitGroups(newGroups)
    return newGroups
  }

  // MARK: Private methods

  @MainActor
  private func commitGroups(_ newGroups: [WorkflowGroup]) {
    groups = newGroups
  }

  private func updateOrAddWorkflows(with newWorkflows: [Workflow]) async -> [WorkflowGroup] {
    // Fix bug when trying to reorder group.
    let oldGroups = await groups
    var newGroups = oldGroups
    for newWorkflow in newWorkflows {
      guard let group = newGroups.first(where: { group in
        group.workflows.map(\.id).contains(newWorkflow.id)
      })
      else { continue }

      guard let groupIndex = newGroups.firstIndex(of: group) else { continue }

      guard let workflowIndex = group.workflows.firstIndex(where: { $0.id == newWorkflow.id })
      else {
        newGroups[groupIndex].workflows.append(newWorkflow)
        continue
      }

      let oldWorkflow = oldGroups[groupIndex].workflows[workflowIndex]
      if oldWorkflow == newWorkflow {
        continue
      }

      newGroups[groupIndex].workflows[workflowIndex] = newWorkflow
    }
    return newGroups
  }
}
