import Foundation

final class DetailCommandContainerActionReducer {
  static func reduce(_ action: CommandContainerAction, command: inout Command, workflow: inout Workflow) {
    switch action {
    case .run:
      break
    case .delete:
      workflow.commands.removeAll(where: { $0.id == command.id })
    case .toggleIsEnabled(let isEnabled):
      command.isEnabled = isEnabled
    case .toggleNotify(let newValue):
      command.notification = newValue
    }
  }
}
