import Foundation

class ViewModelMapperFactory {
  func groupMapper() -> GroupViewModelMapping {
    GroupViewModelMapper(workflowMapper: workflowMapper())
  }

  func workflowMapper() -> WorkflowViewModelMapping {
    WorkflowViewModelMapper(commandMapper: commandMapper(),
                            keyboardShortcutMapper: keyboardShortcutMapper())
  }

  func commandMapper() -> CommandViewModelMapping {
    CommandViewModelMapper()
  }

  func keyboardShortcutMapper() -> KeyboardShortcutViewModelMapping {
    KeyboardShortcutViewModelMapper()
  }

  func applicationMapper() -> ApplicationViewModelMapping {
    ApplicationViewModelMapper()
  }
}
