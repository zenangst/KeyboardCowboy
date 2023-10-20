import SwiftUI

struct WorkflowCommandListScrollView: View {
  @Environment(\.openWindow) var openWindow
  var namespace: Namespace.ID
  @EnvironmentObject var applicationStore: ApplicationStore
  private let triggerPublisher: TriggerPublisher
  private let publisher: CommandsPublisher
  private let workflowId: String
  @ObservedObject private var selectionManager: SelectionManager<CommandViewModel>
  @State private var dropOverlayIsVisible: Bool = false
  @State private var dropUrls = Set<URL>()
  private var focusPublisher = FocusPublisher<CommandViewModel>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void
  private let focus: FocusState<AppFocus?>.Binding

  @FocusState var isFocused: Bool

  init(_ focus: FocusState<AppFocus?>.Binding,
       publisher: CommandsPublisher,
       triggerPublisher: TriggerPublisher,
       namespace: Namespace.ID,
       workflowId: String,
       selectionManager: SelectionManager<CommandViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.publisher = publisher
    self.triggerPublisher = triggerPublisher
    self.focus = focus
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
          CommandView(Binding.readonly(command),
                      publisher: publisher,
                      focusPublisher: focusPublisher,
                      selectionManager: selectionManager,
                      workflowId: workflowId,
                      onCommandAction: onAction, onAction: { action in
            onAction(.commandView(workflowId: workflowId, action: action))
          })
          .contextMenu(menuItems: {
            WorkflowCommandListContextMenuView(
              command,
              workflowId: workflowId,
              publisher: publisher,
              selectionManager: selectionManager,
              onAction: onAction
            )
          })
          .onTapGesture {
            selectionManager.handleOnTap(publisher.data.commands, element: command)
            focusPublisher.publish(command.id)
          }
        }
        .focused($isFocused)
        .onChange(of: isFocused, perform: { newValue in
          guard newValue else { return }

          guard let lastSelection = selectionManager.lastSelection else { return }

          withAnimation {
            scrollViewProxy?.scrollTo(lastSelection)
          }
        })
        .padding(.vertical, 5)
        .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
          switch triggerPublisher.data {
          case .applications:
            focus.wrappedValue = .detail(.applicationTriggers)
          case .keyboardShortcuts:
            focus.wrappedValue = .detail(.keyboardShortcuts)
          case .empty:
            focus.wrappedValue = .detail(.name)
          }
        })
        .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
          focus.wrappedValue = .groups
        })
        .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
          selectionManager.selections = Set(publisher.data.commands.map(\.id))
        })
        .onMoveCommand(perform: { direction in
          if let elementID = selectionManager.handle(direction, publisher.data.commands,
                                                     proxy: scrollViewProxy) {
            focusPublisher.publish(elementID)
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
