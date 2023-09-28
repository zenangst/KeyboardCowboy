import SwiftUI
import Apps

struct SingleDetailView: View {
  @Namespace var namespace

  enum Action {
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case dropUrls(workflowId: Workflow.ID, urls: [URL])
    case duplicate(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case removeCommands(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case removeTrigger(workflowId: Workflow.ID)
    case togglePassthrough(workflowId: Workflow.ID, newValue: Bool)
    case runWorkflow(workflowId: Workflow.ID)
    case setIsEnabled(workflowId: Workflow.ID, isEnabled: Bool)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case updateExecution(workflowId: Workflow.ID, execution: DetailViewModel.Execution)
    case updateHoldDuration(workflowId: Workflow.ID, holdDuration: Double?)
    case updateKeyboardShortcuts(workflowId: Workflow.ID, 
                                 passthrough: Bool,
                                 holdDuration: Double?,
                                 keyboardShortcuts: [KeyShortcut])
    case updateName(workflowId: Workflow.ID, name: String)
  }
  var focus: FocusState<AppFocus?>.Binding
  @Environment(\.openWindow) var openWindow
  @EnvironmentObject var detailPublisher: DetailPublisher
  @State var overlayOpacity: CGFloat = 0
  private let onAction: (Action) -> Void

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    let shouldShowCommandList = detailPublisher.data.trigger != nil ||
                               !detailPublisher.data.commands.isEmpty
    ScrollViewReader { proxy in
        VStack(alignment: .leading) {
          WorkflowInfoView(focus, detailPublisher: detailPublisher, onAction: { action in
            switch action {
            case .updateName(let name):
              onAction(.updateName(workflowId: detailPublisher.data.id, name: name))
            case .setIsEnabled(let isEnabled):
              onAction(.setIsEnabled(workflowId: detailPublisher.data.id, isEnabled: isEnabled))
            }
          })
          .padding(.horizontal, 4)
          .padding(.vertical, 12)
          .id(detailPublisher.data.id)
          WorkflowTriggerListView(focus, data: detailPublisher.data,
                                  applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                                  keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                                  onAction: onAction)
            .id(detailPublisher.data.id)
        }
        .padding([.top, .leading, .trailing])
        .padding(.bottom, 32)
        .background(alignment: .bottom, content: { 
          SingleDetailBackgroundView()
            .drawingGroup()
        })

      WorkflowCommandListView(
        focus,
        namespace: namespace,
        publisher: detailPublisher,
        selectionManager: commandSelectionManager,
        scrollViewProxy: proxy,
        onAction: { action in
          onAction(action)
        })
      .opacity(shouldShowCommandList ? 1 : 0)
      .id(detailPublisher.data.id)
    }
    .labelStyle(HeaderLabelStyle())
    .focusScope(namespace)
    .frame(maxHeight: .infinity, alignment: .top)
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    SingleDetailView($focus,
                     applicationTriggerSelectionManager: .init(),
                     commandSelectionManager: .init(),
                     keyboardShortcutSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 900)
  }
}
