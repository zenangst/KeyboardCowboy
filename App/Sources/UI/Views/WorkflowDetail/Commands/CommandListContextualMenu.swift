import SwiftUI

struct CommandListContextualMenu: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let command: CommandViewModel
  private let detailPublisher: CommandsPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let onDuplicate: (Command.ID) -> Void

  init(_ command: CommandViewModel, publisher: CommandsPublisher,
       selectionManager: SelectionManager<CommandViewModel>, onDuplicate: @escaping (Command.ID) -> Void)
  {
    self.command = command
    detailPublisher = publisher
    self.selectionManager = selectionManager
    self.onDuplicate = onDuplicate
  }

  var body: some View {
    Button("Duplicate", action: {
      updater.modifyWorkflow(using: transaction) { workflow in
        let commandIds = !selectionManager.selections.isEmpty
          ? selectionManager.selections
          : Set(arrayLiteral: command.id)
        var lastCopyId: Command.ID?
        for commandId in commandIds {
          guard let index = workflow.commands.firstIndex(where: { $0.id == commandId }) else { continue }

          let copy = workflow.commands[index].copy()
          workflow.commands.insert(copy, at: index)
          lastCopyId = copy.id
        }
        if let lastCopyId {
          onDuplicate(lastCopyId)
        }
      }
    })
    Button("Remove", action: {
      updater.modifyWorkflow(using: transaction) { workflow in
        let commandIds = !selectionManager.selections.isEmpty
          ? selectionManager.selections
          : Set(arrayLiteral: command.id)
        if !selectionManager.selections.isEmpty {
          workflow.commands.removeAll(where: { commandIds.contains($0.id) })
        } else {
          workflow.commands.removeAll(where: { $0.id == command.id })
        }
      }
    })
  }
}
