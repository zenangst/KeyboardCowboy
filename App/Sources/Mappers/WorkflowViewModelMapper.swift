import Foundation
import LogicFramework
import ViewKit

protocol WorkflowViewModelMapping {
  func map(_ models: [Workflow]) -> [WorkflowViewModel]
}

class WorkflowViewModelMapper: WorkflowViewModelMapping {
  let commandMapper: CommandViewModelMapping
  let combinationMapper: CombinationViewModelMapping

  init(commandMapper: CommandViewModelMapping,
       combinationMapper: CombinationViewModelMapping) {
    self.commandMapper = commandMapper
    self.combinationMapper = combinationMapper
  }

  func map(_ models: [Workflow]) -> [WorkflowViewModel] {
    models.compactMap {
      .init(id: $0.id,
            name: $0.name,
            combinations: combinationMapper.map($0.keyboardShortcuts),
            commands: commandMapper.map($0.commands))
    }
  }
}
