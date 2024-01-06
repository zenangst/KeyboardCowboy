import SwiftUI

struct WorkflowCommandListContextMenuView: View {
  private let command: CommandViewModel
  private let workflowId: String
  private let detailPublisher: CommandsPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ command: CommandViewModel,
       workflowId: String,
       publisher: CommandsPublisher,
       selectionManager: SelectionManager<CommandViewModel>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.command = command
    self.workflowId = workflowId
    self.detailPublisher = publisher
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    let commandIds = !selectionManager.selections.isEmpty
    ? selectionManager.selections
    : Set(arrayLiteral: command.id)
    Button("Run", action: {
      onAction(.commandView(workflowId: workflowId, action: .run(payload: .init(workflowId: workflowId, commandId: command.id))))
    })
    Divider()
    Button("Duplicate", action: {
      onAction(.duplicate(workflowId: workflowId, commandIds: commandIds))
    })
    Button("Remove", action: {
      if !selectionManager.selections.isEmpty {
        onAction(.removeCommands(workflowId: workflowId, commandIds: commandIds))
      } else {
        onAction(.commandView(workflowId: workflowId, action: .remove(payload: .init(workflowId: workflowId, commandId: command.id))))
      }
    })

  }
}

