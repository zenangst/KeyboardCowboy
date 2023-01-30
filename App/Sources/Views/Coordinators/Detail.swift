import Foundation

final class DetailCommandContainerActionReducer {
  static func reduce(_ action: CommandContainerAction, command: Command, workflow: inout Workflow) async {
    switch action {
    case .run:
      break
    case .delete:
      workflow.commands.removeAll(where: { $0.id == command.id })
    }
  }
}
