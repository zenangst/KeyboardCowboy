import Foundation

extension KeyboardCowboyConfiguration {
  @discardableResult mutating func update<Value>(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    commandID: Command.ID,
    keyPath: WritableKeyPath<Command, Value>,
    newValue: Value,
  ) -> Bool {
    guard let (groupIndex, workflowIndex, commandIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID, commandID: commandID) else {
      return false
    }

    groups[groupIndex].workflows[workflowIndex].commands[commandIndex][keyPath: keyPath] = newValue
    return true
  }

  @discardableResult mutating func modify(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    commandID: Command.ID,
    modify: (inout Command) -> Void,
  ) -> Bool {
    guard let (groupIndex, workflowIndex, commandIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID, commandID: commandID) else {
      return false
    }

    var command = groups[groupIndex].workflows[workflowIndex].commands[commandIndex]
    let oldCommand = command

    modify(&command)

    guard command != oldCommand else { return false }

    groups[groupIndex].workflows[workflowIndex].commands[commandIndex] = command
    return true
  }

  @discardableResult mutating func replace(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    commandID: Command.ID,
    command newCommand: Command,
  ) -> Bool {
    guard let (groupIndex, workflowIndex, commandIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID, commandID: commandID) else {
      return false
    }

    groups[groupIndex].workflows[workflowIndex].commands[commandIndex] = newCommand
    return true
  }

  @discardableResult mutating func append(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    command newCommand: Command,
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }

    groups[groupIndex].workflows[workflowIndex].commands.append(newCommand)
    return true
  }

  @discardableResult mutating func insert(
    groupID: WorkflowGroup.ID,
    workflowID: Workflow.ID,
    command newCommand: Command,
    at index: Int,
  ) -> Bool {
    guard let (groupIndex, workflowIndex) = resolveIndexes(groupID: groupID, workflowID: workflowID) else {
      return false
    }

    if groups[groupIndex].workflows[workflowIndex].commands.isEmpty {
      groups[groupIndex].workflows[workflowIndex].commands.append(newCommand)
    } else {
      let safeIndex = max(min(index, groups[groupIndex].workflows[workflowIndex].commands.count), 0)
      groups[groupIndex].workflows[workflowIndex].commands.insert(newCommand, at: safeIndex)
    }
    return true
  }
}
