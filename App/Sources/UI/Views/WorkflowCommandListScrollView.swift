import Bonzai
import SwiftUI

struct WorkflowCommandListScrollView: View {
  @EnvironmentObject private var updater: ConfigurationUpdater
  @EnvironmentObject private var transaction: UpdateTransaction
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObservedObject private var selectionManager: SelectionManager<CommandViewModel>
  @ObservedObject private var publisher: CommandsPublisher
  private let scrollViewProxy: ScrollViewProxy?
  private let triggerPublisher: TriggerPublisher
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding
  private var namespace: Namespace.ID
  @State private var dropKind: TargetedKind = .reorder

  init(_ focus: FocusState<AppFocus?>.Binding,
       publisher: CommandsPublisher,
       triggerPublisher: TriggerPublisher,
       namespace: Namespace.ID,
       workflowId: String,
       selectionManager: SelectionManager<CommandViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil) {
    self.focus = focus
    self.publisher = publisher
    self.triggerPublisher = triggerPublisher
    self.workflowId = workflowId
    self.namespace = namespace
    self.selectionManager = selectionManager
    self.scrollViewProxy = scrollViewProxy
  }

  var body: some View {
    CompatList {
      ForEach(publisher.data.commands, id: \.id) { command in
        CommandView(focus, command: Binding.readonly(command),
                    publisher: publisher, selectionManager: selectionManager,
                    workflowId: workflowId)
        .dropDestination(CommandListDropItem.self,
                         color: .accentColor,
                         kind: dropKind,
                         onDrop: { items, location in
          var urls = [URL]()
          for item in items {
            switch item {
            case .command:
              let ids = Array(selectionManager.selections)
              guard let (from, destination) = publisher.data.commands.moveOffsets(
                for: command,
                with: ids
              ) else {
                return false
              }

              withAnimation(WorkflowCommandListView.animation) {
                publisher.data.commands.move(fromOffsets: from, toOffset: destination)
              }
              updater.modifyWorkflow(using: transaction) { workflow in
                workflow.commands.move(fromOffsets: from, toOffset: destination)
              }
            case .url(let url):
              urls.append(url)
            }
          }

          if !urls.isEmpty {
            updater.modifyWorkflow(using: transaction) { workflow in
              let commands = DropCommandsController.generateCommands(from: urls, applications: applicationStore.applications)
              workflow.commands.append(contentsOf: commands)
            }
          }
          return true
        })
        .contentShape(Rectangle())
        .contextMenu(menuItems: {
          WorkflowCommandListContextMenuView(command, publisher: publisher, selectionManager: selectionManager)
        })
        .focusable(focus, as: .detail(.command(command.id))) {
          selectionManager.handleOnTap(publisher.data.commands, element: command)
        }
      }
      .padding(.vertical, 5)
      .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
        switch triggerPublisher.data {
        case .applications:
          focus.wrappedValue = .detail(.applicationTriggers)
        case .keyboardShortcuts:
          focus.wrappedValue = .detail(.keyboardShortcuts)
        case .snippet:
          focus.wrappedValue = .detail(.addSnippetTrigger)
        case .empty:
          focus.wrappedValue = .detail(.addAppTrigger)
        }
      })
      .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
        selectionManager.publish(Set(publisher.data.commands.map(\.id)))
      })
      .onMoveCommand(perform: { direction in
        if let elementID = selectionManager.handle(direction, publisher.data.commands,
                                                   proxy: scrollViewProxy) {
          focus.wrappedValue = .detail(.command(elementID))
        }
      })
      .onDeleteCommand {
        let allCommandsAreSelected = selectionManager.selections.count == publisher.data.commands.count
        withAnimation(allCommandsAreSelected ? .default : .none) {
          updater.modifyWorkflow(using: transaction) {
            $0.commands.removeAll(where: { selectionManager.selections.contains($0.id) })
          }
        }
      }
      .padding(8)
    }
    .focused(focus, equals: .detail(.commands))
    .matchedGeometryEffect(id: "command-list", in: namespace)
  }
}
