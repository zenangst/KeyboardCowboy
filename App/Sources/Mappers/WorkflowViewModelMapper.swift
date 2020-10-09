import Foundation
import LogicFramework
import ViewKit

protocol WorkflowViewModelMapping {
  func map(_ models: [Workflow]) -> [WorkflowViewModel]
  func map(_ model: Workflow) -> WorkflowViewModel
}

class WorkflowViewModelMapper: WorkflowViewModelMapping {
  let commandMapper: CommandViewModelMapping
  let keyboardShortcutMapper: KeyboardShortcutViewModelMapping

  init(commandMapper: CommandViewModelMapping,
       keyboardShortcutMapper: KeyboardShortcutViewModelMapping) {
    self.commandMapper = commandMapper
    self.keyboardShortcutMapper = keyboardShortcutMapper
  }

  func map(_ models: [Workflow]) -> [WorkflowViewModel] {
    models.compactMap(map(_:))
  }

  func map(_ model: Workflow) -> WorkflowViewModel {
    WorkflowViewModel(id: model.id, name: model.name,
                      keyboardShortcuts: keyboardShortcutMapper.map(model.keyboardShortcuts),
                      commands: commandMapper.map(model.commands))
  }
}
