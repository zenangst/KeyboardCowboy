import SwiftUI

struct WorkflowCommandListScrollView: View {
  @Environment(\.openWindow) var openWindow
  var namespace: Namespace.ID
  @EnvironmentObject var applicationStore: ApplicationStore
  private let detailPublisher: DetailPublisher
  @ObservedObject private var selectionManager: SelectionManager<CommandViewModel>
  @State private var dropOverlayIsVisible: Bool = false
  @State private var dropUrls = Set<URL>()
  private var focusPublisher = FocusPublisher<CommandViewModel>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void
  private let focus: FocusState<AppFocus?>.Binding

  @FocusState var isFocused: Bool

  init(_ focus: FocusState<AppFocus?>.Binding,
       detailPublisher: DetailPublisher,
       namespace: Namespace.ID,
       selectionManager: SelectionManager<CommandViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.detailPublisher = detailPublisher
    self.focus = focus
    self.namespace = namespace
    self.selectionManager = selectionManager
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(detailPublisher.data.commands.lazy, id: \.id) { command in
          CommandView(Binding.readonly(command),
                      detailPublisher: detailPublisher,
                      focusPublisher: focusPublisher,
                      selectionManager: selectionManager,
                      workflowId: detailPublisher.data.id,
                      onCommandAction: onAction, onAction: { action in
            onAction(.commandView(workflowId: detailPublisher.data.id, action: action))
          })
          .contextMenu(menuItems: {
            WorkflowCommandListContextMenuView(
              command,
              detailPublisher: detailPublisher,
              selectionManager: selectionManager,
              onAction: onAction
            )
          })
          .onTapGesture {
            selectionManager.handleOnTap(detailPublisher.data.commands, element: command)
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
          switch detailPublisher.data.trigger {
          case .applications:
            focus.wrappedValue = .detail(.applicationTriggers)
          case .keyboardShortcuts:
            focus.wrappedValue = .detail(.keyboardShortcuts)
          case .none:
            focus.wrappedValue = .detail(.name)
          }
        })
        .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
          focus.wrappedValue = .groups
        })
        .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
          selectionManager.selections = Set(detailPublisher.data.commands.map(\.id))
        })
        .onMoveCommand(perform: { direction in
          if let elementID = selectionManager.handle(direction, detailPublisher.data.commands,
                                                     proxy: scrollViewProxy) {
            focusPublisher.publish(elementID)
          }
        })
        .onDeleteCommand {
          if selectionManager.selections.count == detailPublisher.data.commands.count {
            withAnimation {
              onAction(.removeCommands(workflowId: detailPublisher.data.id, commandIds: selectionManager.selections))
            }
          } else {
            onAction(.removeCommands(workflowId: detailPublisher.data.id, commandIds: selectionManager.selections))
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
