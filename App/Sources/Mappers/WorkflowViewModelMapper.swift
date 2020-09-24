import Foundation
import LogicFramework
import ViewKit

class WorkflowViewModelMapper {
  let commandMapper = CommandViewModelMapper()
  let combinationMapper = CombinationViewModelMapper()

  func map(_ models: [Workflow]) -> [WorkflowViewModel] {
    models.compactMap {
      .init(name: $0.name,
            combinations: combinationMapper.map($0.keyboardShortcuts),
            commands: commandMapper.map($0.commands))
    }
  }
}
