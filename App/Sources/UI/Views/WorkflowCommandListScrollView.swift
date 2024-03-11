import SwiftUI

struct WorkflowCommandListScrollView: View {
  @Environment(\.openWindow) private var openWindow
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObservedObject private var selectionManager: SelectionManager<CommandViewModel>
  private let onAction: (SingleDetailView.Action) -> Void
  private let publisher: CommandsPublisher
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
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
    self.publisher = publisher
    self.triggerPublisher = triggerPublisher
    self.workflowId = workflowId
    self.namespace = namespace
    self.selectionManager = selectionManager
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(publisher.data.commands.lazy, id: \.id) { command in
          CommandView(
            focus,
            command: Binding.readonly(command),
            publisher: publisher,
            selectionManager: selectionManager,
            workflowId: workflowId,
            onCommandAction: onAction, onAction: { action in
            onAction(.commandView(workflowId: workflowId, action: action))
          })
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

                onAction(.moveCommand(workflowId: workflowId, indexSet: from, toOffset: destination))
              case .url(let url):
                urls.append(url)
              }
            }

            if !urls.isEmpty {
              onAction(.dropUrls(workflowId: workflowId, urls: urls))
            }
            return true
          })
          .contentShape(Rectangle())
          .contextMenu(menuItems: {
            WorkflowCommandListContextMenuView(
              command,
              workflowId: workflowId,
              publisher: publisher,
              selectionManager: selectionManager,
              onAction: onAction
            )
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
          selectionManager.selections = Set(publisher.data.commands.map(\.id))
        })
        .onMoveCommand(perform: { direction in
          if let elementID = selectionManager.handle(direction, publisher.data.commands,
                                                     proxy: scrollViewProxy) {
            focus.wrappedValue = .detail(.command(elementID))
          }
        })
        .onDeleteCommand {
          if selectionManager.selections.count == publisher.data.commands.count {
            withAnimation {
              onAction(.removeCommands(workflowId: workflowId, commandIds: selectionManager.selections))
            }
          } else {
            onAction(.removeCommands(workflowId: workflowId, commandIds: selectionManager.selections))
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .focused(focus, equals: .detail(.commands))
      .matchedGeometryEffect(id: "command-list", in: namespace)
    }
  }
}
