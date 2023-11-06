import SwiftUI

final class GroupStore: ObservableObject {
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
    commitGroups(newGroups)
  }

  @MainActor
  func copy(_ workflowIds: Set<Workflow.ID>, to newGroupId: WorkflowGroup.ID) {
    for workflowId in workflowIds {
      guard let oldGroup = groupForWorkflow(workflowId),
            var newGroup = groups.first(where: { $0.id == newGroupId }),
            let index = oldGroup.workflows.firstIndex(where: { $0.id == workflowId }) else { continue }

      let workflow = oldGroup.workflows[index]
      newGroup.workflows.append(workflow.copy())

      updateGroups([oldGroup, newGroup])
    }
  }

  @MainActor
  func move(_ workflowIds: Set<Workflow.ID>, to newGroupId: WorkflowGroup.ID) {
    for workflowId in workflowIds {
      guard var oldGroup = groupForWorkflow(workflowId),
            var newGroup = groups.first(where: { $0.id == newGroupId }),
            oldGroup.id != newGroupId,
            let index = oldGroup.workflows.firstIndex(where: { $0.id == workflowId }) else { continue }

      let workflow = oldGroup.workflows[index]
      oldGroup.workflows.remove(at: index)
      newGroup.workflows.append(workflow)

      updateGroups([oldGroup, newGroup])
    }
  }

  @MainActor
  func move(source: IndexSet, destination: Int) {
    var newGroups = groups
    newGroups.move(fromOffsets: source, toOffset: destination)
    commitGroups(newGroups)
  }

  @MainActor
  func updateGroups(_ groups: Set<WorkflowGroup>) {
    let oldGroups = self.groups
    var newGroups = oldGroups
    for group in groups {
      guard let index = oldGroups.firstIndex(where: { $0.id == group.id }) else { return }
      newGroups[index] = group
    }
    commitGroups(newGroups)
  }

  @MainActor
  func removeGroups(with ids: Set<WorkflowGroup.ID>) {
    var newGroups = groups
    newGroups.removeAll(where: { ids.contains($0.id) })
    commitGroups(newGroups)
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

  @discardableResult
  @MainActor
  func commit(_ newWorkflows: [Workflow]) -> [WorkflowGroup] {
    let newGroups = updateOrAddWorkflows(newWorkflows, oldGroups: groups)
    commitGroups(newGroups)
    return newGroups
  }

  // MARK: Private methods

  @MainActor
  private func groupForWorkflow(_ workflowId: Workflow.ID) -> WorkflowGroup? {
    groups.first(where: {
      $0.workflows.map(\.id).contains(workflowId)
    })
  }

  @MainActor
  private func commitGroups(_ newGroups: [WorkflowGroup]) {
    groups = newGroups
  }

  private func updateOrAddWorkflows(_ newWorkflows: [Workflow], oldGroups: [WorkflowGroup]) -> [WorkflowGroup] {
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

  private func updateOrAddWorkflows(with newWorkflows: [Workflow]) async -> [WorkflowGroup] {
    updateOrAddWorkflows(newWorkflows, oldGroups: await groups)
  }
}
