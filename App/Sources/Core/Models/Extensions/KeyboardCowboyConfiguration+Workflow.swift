import Foundation

extension KeyboardCowboyConfiguration {
  @discardableResult mutating func update<Value>(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    keyPath: WritableKeyPath<Workflow, Value>,
    newValue: Value
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }
    groups[groupIndex].workflows[workflowIndex][keyPath: keyPath] = newValue
    return true
  }

  @discardableResult mutating func modify(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    modify: (inout Workflow) -> Void
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }
    var workflow = groups[groupIndex].workflows[workflowIndex]
    modify(&workflow)
    groups[groupIndex].workflows[workflowIndex] = workflow
    return true
  }

  @discardableResult mutating func replace(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    workflow newWorkflow: Workflow
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }

    groups[groupIndex].workflows[workflowIndex] = newWorkflow
    return true
  }

  @discardableResult mutating func append(
    groupID: WorkflowGroup.ID,
    workflow newWorkflow: Workflow
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    groups[groupIndex].workflows.append(newWorkflow)
    return true
  }

  @discardableResult mutating func insert(
    groupID: WorkflowGroup.ID,
    workflow newWorkflow: Workflow,
    at index: Int
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    if groups[groupIndex].workflows.isEmpty {
      groups[groupIndex].workflows.append(newWorkflow)
    } else {
      let safeIndex = max(min(index, groups[groupIndex].workflows.count), 0)
      groups[groupIndex].workflows.insert(newWorkflow, at: safeIndex)
    }
    return true
  }
}
