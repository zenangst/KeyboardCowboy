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
  @EnvironmentObject var triggerPublisher: TriggerPublisher
  @EnvironmentObject var infoPublisher: InfoPublisher
  @EnvironmentObject var commandPublisher: CommandsPublisher

  @State var overlayOpacity: CGFloat = 0
  private let onAction: (Action) -> Void

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
        VStack(alignment: .leading) {
          WorkflowInfoView(focus, publisher: infoPublisher, 
                           onInsertTab: {
            switch triggerPublisher.data {
            case .applications:
              focus.wrappedValue = .detail(.applicationTriggers)
            case .keyboardShortcuts:
              focus.wrappedValue = .detail(.keyboardShortcuts)
            case .empty:
              focus.wrappedValue = .detail(.name)
            }
          }, onAction: { action in
            switch action {
            case .updateName(let name):
              onAction(.updateName(workflowId: infoPublisher.data.id, name: name))
            case .setIsEnabled(let isEnabled):
              onAction(.setIsEnabled(workflowId: infoPublisher.data.id, isEnabled: isEnabled))
            }
          })
          .environmentObject(commandSelectionManager)
          .padding(.horizontal, 4)
          .padding(.vertical, 12)
          WorkflowTriggerListView(focus,
                                  workflowId: infoPublisher.data.id,
                                  publisher: triggerPublisher,
                                  applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                                  keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                                  onAction: onAction)
          .id(infoPublisher.data.id)
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
        workflowId: infoPublisher.data.id,
        isPrimary: Binding<Bool>.init(get: {
          switch triggerPublisher.data {
          case .applications(let array): !array.isEmpty
          case .keyboardShortcuts(let keyboardTrigger): !keyboardTrigger.shortcuts.isEmpty
          case .empty: false
          }
        }, set: { _ in }),
        publisher: commandPublisher,
        triggerPublisher: triggerPublisher,
        selectionManager: commandSelectionManager,
        scrollViewProxy: proxy,
        onAction: { action in
          onAction(action)
        })
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
                     keyboardShortcutSelectionManager: .init(),
                     triggerPublisher: DesignTime.triggerPublisher,
                     infoPublisher: DesignTime.infoPublisher,
                     commandPublisher: DesignTime.commandsPublisher) { _ in }
      .designTime()
      .frame(height: 900)
  }
}
