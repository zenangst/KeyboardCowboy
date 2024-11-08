import SwiftUI

struct CommandListContextualMenu: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let command: CommandViewModel
  private let detailPublisher: CommandsPublisher
  private let selectionManager: SelectionManager<CommandViewModel>

  init(_ command: CommandViewModel, publisher: CommandsPublisher, selectionManager: SelectionManager<CommandViewModel>) {
    self.command = command
    self.detailPublisher = publisher
    self.selectionManager = selectionManager
  }

  var body: some View {
    let commandIds = !selectionManager.selections.isEmpty
    ? selectionManager.selections
    : Set(arrayLiteral: command.id)
    Button("Duplicate", action: {
      updater.modifyWorkflow(using: transaction) { workflow in
        for commandId in commandIds {
          guard let index = workflow.commands.firstIndex(where: { $0.id == commandId }) else { continue }
          let copy = workflow.commands[index].copy()
          workflow.commands.insert(copy, at: index)
        }
      }
    })
    Button("Remove", action: {
      updater.modifyWorkflow(using: transaction) { workflow in
        if !selectionManager.selections.isEmpty {
          workflow.commands.removeAll(where: { commandIds.contains($0.id) })
        } else {
          workflow.commands.removeAll(where: { $0.id == command.id })
        }
      }
    })
  }
}

