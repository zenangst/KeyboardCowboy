import Foundation

extension KeyboardCowboyConfiguration {
  @discardableResult mutating func update<Value>(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    keyPath: WritableKeyPath<Workflow, Value>,
    newValue: Value,
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
    modify: (inout Workflow) -> Void,
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }

    var workflow = groups[groupIndex].workflows[workflowIndex]
    let oldWorkflow = workflow
    modify(&workflow)

    guard workflow != oldWorkflow else { return false }

    groups[groupIndex].workflows[workflowIndex] = workflow

    updateHoldForOnMatchingSequences(workflow, groupIndex: groupIndex)

    return true
  }

  @discardableResult mutating func replace(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    workflow newWorkflow: Workflow,
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }

    groups[groupIndex].workflows[workflowIndex] = newWorkflow
    return true
  }

  @discardableResult mutating func append(
    groupID: WorkflowGroup.ID,
    workflow newWorkflow: Workflow,
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    groups[groupIndex].workflows.append(newWorkflow)
    return true
  }

  @discardableResult mutating func insert(
    groupID: WorkflowGroup.ID,
    workflow newWorkflow: Workflow,
    at index: Int,
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

  private mutating func updateHoldForOnMatchingSequences(_ newWorkflow: Workflow, groupIndex: Int) {
    if case let .keyboardShortcuts(newTrigger) = newWorkflow.trigger,
       let holdDuration = newTrigger.holdDuration,
       holdDuration > 0,
       newTrigger.shortcuts.count > 1,
       let targetShortcut = newTrigger.shortcuts.first
    {
      for (index, workflow) in groups[groupIndex].workflows.enumerated() where workflow.id != newWorkflow.id {
        guard case var .keyboardShortcuts(trigger) = workflow.trigger,
              !workflow.machPortConditions.isLeaderKey,
              let firstShortcut = trigger.shortcuts.first,
              firstShortcut.key == targetShortcut.key,
              !newTrigger.leaderKey else { continue }

        var workflow = workflow
        trigger.holdDuration = holdDuration
        workflow.trigger = .keyboardShortcuts(trigger)
        groups[groupIndex].workflows[index] = workflow
      }
    }
  }
}
