import Foundation
import LogicFramework
import ViewKit

protocol WorkflowViewModelMapping {
  func map(_ models: [Workflow]) -> [WorkflowViewModel]
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
    models.compactMap {
      .init(id: $0.id,
            name: $0.name,
            keyboardShortcuts: keyboardShortcutMapper.map($0.keyboardShortcuts),
            commands: commandMapper.map($0.commands))
    }
  }
}
