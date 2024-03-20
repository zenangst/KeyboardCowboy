import SwiftUI

struct ContainerView: View {
  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(ContentListView.Action)
    case detail(DetailView.Action)
  }

  @Environment(\.undoManager) private var undoManager
  @ObservedObject private var navigationPublisher = NavigationPublisher()
  @Binding private var contentState: ContentStore.State

  private let onAction: (Action, UndoManager?) -> Void
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupsSelectionManager: SelectionManager<GroupViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let publisher: ContentPublisher
  private let triggerPublisher: TriggerPublisher
  private let infoPublisher: InfoPublisher
  private let commandPublisher: CommandsPublisher
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentState: Binding<ContentStore.State>,
       publisher: ContentPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupsSelectionManager: SelectionManager<GroupViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (Action, UndoManager?) -> Void) {
    _contentState = contentState
    self.focus = focus
    self.publisher = publisher
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.configSelectionManager = configSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.groupsSelectionManager = groupsSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.triggerPublisher = triggerPublisher
    self.infoPublisher = infoPublisher
    self.commandPublisher = commandPublisher
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        Group {
          SidebarView(focus,
                      configSelectionManager: configSelectionManager,
                      groupSelectionManager: groupsSelectionManager,
                      contentSelectionManager: contentSelectionManager,
                      onAction: { onAction(.sidebar($0), undoManager) })
            .onChange(of: contentState, perform: { _ in
              guard let workflowId = contentSelectionManager.lastSelection,
                 let groupId = groupsSelectionManager.lastSelection else { return }
              onAction(.sidebar(.selectGroups([groupId])), undoManager)
            })
            .opacity(contentState == .initialized ? 1 : 0)
            .frame(height: contentState == .initialized ? nil : 0)

          Text("Loading...")
            .opacity(contentState == .loading ? 1 : 0)
            .frame(height: contentState == .loading ? nil : 0)
        }
        .navigationSplitViewColumnWidth(ideal: 250)
      },
      content: {
        Group {
          ContentListView(focus,
                          contentSelectionManager: contentSelectionManager,
                          groupSelectionManager: groupsSelectionManager,
                          onAction: {
            onAction(.content($0), undoManager)

            if case .addWorkflow = $0 {
              Task { @MainActor in focus.wrappedValue = .detail(.name) }
            }
          })
          .onAppear {
            if !publisher.data.isEmpty {
              DispatchQueue.main.async {
                focus.wrappedValue = .workflows
              }
            }
          }
          .opacity(contentState == .initialized ? 1 : 0)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 250)
      },
      detail: {
        Group {
          DetailView(focus,
                     applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                     commandSelectionManager: commandSelectionManager,
                     keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                     triggerPublisher: triggerPublisher,
                     infoPublisher: infoPublisher,
                     commandPublisher: commandPublisher,
                     onAction: { onAction(.detail($0), undoManager) })
          .opacity(contentState == .initialized ? 1 : 0)
        }
        .frame(minHeight: 400)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
      })
    .navigationSplitViewStyle(.balanced)
  }
}

struct ContainerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContainerView(
      $focus,
      contentState: .readonly(.initialized),
      publisher: DesignTime.contentPublisher,
      applicationTriggerSelectionManager: .init(),
      commandSelectionManager: .init(),
      configSelectionManager: .init(),
      contentSelectionManager: .init(),
      groupsSelectionManager: .init(),
      keyboardShortcutSelectionManager: .init(),
      triggerPublisher: DesignTime.triggerPublisher,
      infoPublisher: DesignTime.infoPublisher,
      commandPublisher: DesignTime.commandsPublisher
    ) { _, _ in }
      .designTime()
      .frame(height: 800)
  }
}
