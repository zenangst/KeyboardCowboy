import Foundation

extension KeyboardCowboyConfiguration {
  func resolveIndex(groupID: WorkflowGroup.ID) -> Int? {
    groups.firstIndex(where: { $0.id == groupID })
  }

  func resolveIndexes(groupID: WorkflowGroup.ID, workflowID: Workflow.ID) -> (groupIndex: Int, workflowIndex: Int)? {
    guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }),
          let workflowIndex = groups[groupIndex].workflows.firstIndex(where: { $0.id == workflowID })
    else {
      return nil
    }

    return (groupIndex, workflowIndex)
  }

  func resolveIndexes(groupID: WorkflowGroup.ID, workflowID: Workflow.ID, commandID: Command.ID) -> (groupIndex: Int, workflowIndex: Int, commandID: Int)? {
    guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }),
          let workflowIndex = groups[groupIndex].workflows.firstIndex(where: { $0.id == workflowID }),
          let commandID = groups[groupIndex].workflows[workflowIndex].commands.firstIndex(where: { $0.id == commandID })
    else {
      return nil
    }

    return (groupIndex, workflowIndex, commandID)
  }
}
