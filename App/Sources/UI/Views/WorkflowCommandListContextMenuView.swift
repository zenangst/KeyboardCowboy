import SwiftUI

struct WorkflowCommandListContextMenuView: View {
  private let command: CommandViewModel
  private let detailPublisher: DetailPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ command: CommandViewModel,
       detailPublisher: DetailPublisher,
       selectionManager: SelectionManager<CommandViewModel>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.command = command
    self.detailPublisher = detailPublisher
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    let workflowId = detailPublisher.data.id
    let commandIds = !selectionManager.selections.isEmpty
    ? selectionManager.selections
    : Set(arrayLiteral: command.id)
    Button("Run", action: {
      onAction(.commandView(workflowId: workflowId, action: .run(workflowId: workflowId, commandId: command.id)))
    })
    Divider()
    Button("Duplicate", action: {
      onAction(.duplicate(workflowId: workflowId, commandIds: commandIds))
    })
    Button("Remove", action: {
      if !selectionManager.selections.isEmpty {
        onAction(.removeCommands(workflowId: workflowId, commandIds: commandIds))
      } else {
        onAction(.commandView(workflowId: workflowId, action: .remove(workflowId: workflowId, commandId: command.id)))
      }
    })

  }
}

