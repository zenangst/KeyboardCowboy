import Foundation
import LogicFramework

class ViewModelMapperFactory {
  var installedApplications: [Application]

  init(installedApplications: [Application] = []) {
    self.installedApplications = installedApplications
  }

  func groupMapper() -> GroupViewModelMapping {
    GroupViewModelMapper(workflowMapper: workflowMapper())
  }

  func workflowMapper() -> WorkflowViewModelMapping {
    WorkflowViewModelMapper(commandMapper: commandMapper(),
                            keyboardShortcutMapper: keyboardShortcutMapper())
  }

  func commandMapper() -> CommandViewModelMapping {
    CommandViewModelMapper(installedApplications: installedApplications)
  }

  func keyboardShortcutMapper() -> KeyboardShortcutViewModelMapping {
    KeyboardShortcutViewModelMapper()
  }

  func applicationMapper() -> ApplicationViewModelMapping {
    ApplicationViewModelMapper()
  }
}
