import Bonzai
import Inject
import SwiftUI

struct ContainerView: View {
  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(GroupDetailView.Action)
  }

  @ObserveInjection var inject
  @Environment(\.undoManager) private var undoManager
  @ObservedObject private var navigationPublisher = NavigationPublisher()
  @Binding private var contentState: ContentStore.State

  private let onAction: (Action, UndoManager?) -> Void
  private let applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelection: SelectionManager<CommandViewModel>
  private let configSelection: SelectionManager<ConfigurationViewModel>
  private let contentSelection: SelectionManager<GroupDetailViewModel>
  private let groupsSelection: SelectionManager<GroupViewModel>
  private let keyboardShortcutSelection: SelectionManager<KeyShortcut>
  private let publisher: GroupDetailPublisher
  private let triggerPublisher: TriggerPublisher
  private let infoPublisher: InfoPublisher
  private let commandPublisher: CommandsPublisher
  private let detailUpdateTransaction: UpdateTransaction
  private var focus: FocusState<AppFocus?>.Binding

  @MainActor
  init(_ focus: FocusState<AppFocus?>.Binding,
       contentState: Binding<ContentStore.State>,
       detailUpdateTransaction: UpdateTransaction,
       publisher: GroupDetailPublisher,
       applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelection: SelectionManager<CommandViewModel>,
       configSelection: SelectionManager<ConfigurationViewModel>,
       contentSelection: SelectionManager<GroupDetailViewModel>,
       groupsSelection: SelectionManager<GroupViewModel>,
       keyboardShortcutSelection: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (Action, UndoManager?) -> Void) {
    _contentState = contentState
    self.focus = focus
    self.publisher = publisher
    self.applicationTriggerSelection = applicationTriggerSelection
    self.commandSelection = commandSelection
    self.configSelection = configSelection
    self.contentSelection = contentSelection
    self.groupsSelection = groupsSelection
    self.keyboardShortcutSelection = keyboardShortcutSelection
    self.triggerPublisher = triggerPublisher
    self.infoPublisher = infoPublisher
    self.commandPublisher = commandPublisher
    self.onAction = onAction
    self.detailUpdateTransaction = detailUpdateTransaction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView(
          focus,
          configSelection: configSelection,
          groupSelection: groupsSelection,
          workflowSelection: contentSelection,
          onAction: { onAction(.sidebar($0), undoManager) })
        .onChange(of: contentState, perform: { newValue in
          guard newValue == .initialized else { return }
          guard let groupId = groupsSelection.lastSelection else { return }
          onAction(.sidebar(.selectGroups([groupId])), undoManager)
        })
        .navigationSplitViewColumnWidth(ideal: 250)
      },
      content: {
        GroupDetailView(
          focus,
          groupId: groupsSelection.lastSelection ?? groupsSelection.selections.first ?? "empty",
          workflowSelection: contentSelection,
          onAction: {
            onAction(.content($0), undoManager)

            if case .addWorkflow = $0 {
              Task { @MainActor in focus.wrappedValue = .detail(.name) }
            }
          })
        .navigationSplitViewColumnWidth(min: 180, ideal: 250)
      },
      detail: {
        DetailView(
          focus,
          applicationTriggerSelection: applicationTriggerSelection,
          commandSelection: commandSelection,
          keyboardShortcutSelection: keyboardShortcutSelection,
          triggerPublisher: triggerPublisher,
          infoPublisher: infoPublisher,
          commandPublisher: commandPublisher)
        .frame(minHeight: 400)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        .background()
        .environmentObject(detailUpdateTransaction)
      })
    .navigationSplitViewStyle(.balanced)
    .enableInjection()
  }
}

struct ContainerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContainerView(
      $focus,
      contentState: .readonly(.initialized),
      detailUpdateTransaction: .init(groupID: "", workflowID: ""),
      publisher: DesignTime.contentPublisher,
      applicationTriggerSelection: .init(),
      commandSelection: .init(),
      configSelection: .init(),
      contentSelection: .init(),
      groupsSelection: .init(),
      keyboardShortcutSelection: .init(),
      triggerPublisher: DesignTime.triggerPublisher,
      infoPublisher: DesignTime.infoPublisher,
      commandPublisher: DesignTime.commandsPublisher
    ) { _, _ in }
      .designTime()
      .frame(height: 800)
  }
}
