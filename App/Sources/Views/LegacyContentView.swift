import SwiftUI

struct LegacyContentView: View, Equatable {
  enum Action {
    case reveal(Command)
    case run(Command)
  }
  @ObserveInjection var inject

  @StateObject var store: ContentStore

  @State var config = DetailToolbarConfig()
  @State var detailViewSheet: WorkflowView.Sheet?
  @State var sidebarViewSheet: LegacySidebarView.Sheet?
  @State var searchQuery: String
  @State private var groupIds: Set<String>
  @State private var workflowIds: Set<String>

  @Binding private var selectedGroups: [WorkflowGroup]
  @Binding private var selectedWorkflows: [Workflow]

  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.undoManager) private var undoManager

  private var action: (Action) -> Void
  @FocusState private var focus: Focus?

  static var appStorage = AppStorageStore()

  init(_ store: ContentStore,
       selectedGroups: Binding<[WorkflowGroup]>,
       selectedWorkflows: Binding<[Workflow]>,
       focus: FocusState<Focus?>,
       action: @escaping (Action) -> Void) {
    _groupIds = .init(initialValue: Self.appStorage.groupIds)
    _workflowIds = .init(initialValue: Self.appStorage.workflowIds)
    _store = .init(wrappedValue: store)
    _selectedGroups = selectedGroups
    _selectedWorkflows = selectedWorkflows
    _searchQuery = .init(initialValue: "")
    _focus = focus
    self.action = action
  }

  var body: some View {
    NavigationView {
      LegacySidebarView(appStore: store.applicationStore,
                  configurationStore: store.configurationStore,
                  focus: _focus,
                  groupStore: store.groupStore,
                  contentStore: store,
                  sheet: $sidebarViewSheet,
                  selection: $groupIds)
      .toolbar {
        SidebarToolbar(configurationStore: store.configurationStore,
                       contentStore: store, focus: _focus,
                       action: handleSidebar(_:))
      }
      .frame(minWidth: 200, idealWidth: 310)
      .onChange(of: groupIds, perform: { groupIds in
        store.selectGroupsIds(groupIds)
        Self.appStorage.groupIds = store.groupIds
      })

      MainView(action: handleMainAction(_:),
               applicationStore: store.applicationStore,
               focus: _focus, store: store.groupStore, selection: $workflowIds)
      .toolbar { MainViewToolbar(action: handleToolbarAction(_:)) }
      .frame(minWidth: 270)
      .onChange(of: workflowIds, perform: { workflowIds in
        Self.appStorage.workflowIds = workflowIds
        store.selectWorkflowIds(workflowIds)
      })

      VStack {
        if !store.searchStore.query.isEmpty {
          SearchView(applicationStore: store.applicationStore,
                     searchStore: store.searchStore)
          //          .padding()
        } else {

          LegacyDetailView(applicationStore: store.applicationStore,
                     recorderStore: store.recorderStore,
                     shortcutStore: store.shortcutStore,
                     focus: _focus,
                     workflows: $store.selectedWorkflows,
                     sheet: $detailViewSheet,
                     action: handleDetailAction(_:))
          .equatable()
        }
      }
      .toolbar { DetailToolbar(applicationStore: store.applicationStore,
                               config: $config,
                               searchStore: store.searchStore,
                               action: handleDetailToolbarAction(_:)) }
      .frame(minWidth: 380, idealWidth: .infinity, minHeight: 417)
    }
    .onChange(of: scenePhase) { phase in
      guard case .active = phase else { return }
      store.applicationStore.reload()
      store.undoManager = undoManager
    }
    .enableInjection()
  }

  static func ==(lhs: LegacyContentView, rhs: LegacyContentView) -> Bool {
    return true
  }

  // MARK: Private methods

  private func handleSidebar(_ action: SidebarToolbar.Action) {
    switch action {
    case .addGroup:
      let group = WorkflowGroup.empty()
      sidebarViewSheet = .add(group)
    case .toggleSidebar:
      NSApp.keyWindow?.firstResponder?.tryToPerform(
        #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
  }

  private func handleMainAction(_ action: MainView.Action) {
    switch action {
    case .add:
      break
    case .delete(let workflow):
      store.groupStore.remove(workflow)
    }
  }

  private func handleToolbarAction(_ action: MainViewToolbar.Action) {
    switch action {
    case .add:
      let workflow = Workflow.empty()
      store.groupStore.add(workflow)
      workflowIds = [workflow.id]
      DispatchQueue.main.async {
        focus = .detail(.info(workflow))
      }
    }
  }

  private func handleDetailToolbarAction(_ action: DetailToolbar.Action) {
    switch action {
    case .addCommand:
      guard !selectedWorkflows.isEmpty else { return }

      let command: Command = .empty(.application)
      selectedWorkflows[0].commands.append(command)
      detailViewSheet = .edit(command)
    }
  }

  private func handleDetailAction(_ action: LegacyDetailView.Action) -> Void {
    switch action {
    case .workflow(let detailAction):
      switch detailAction {
      case .workflow(let workflowAction):
        switch workflowAction {
        case .commandView(let commandViewAction):
          switch commandViewAction {
          case .commandAction(let commandAction):
            switch commandAction {
            case .edit:
              break
            case .run(let command):
              self.action(.run(command))
            case .reveal(let command):
              self.action(.reveal(command))
            }
          }
        }
      }
    }
  }
}

struct LegacyContentView_Previews: PreviewProvider {
  struct FocusWrapper: View {
    @FocusState var focus: Focus?

    var body: some View {
      LegacyContentView(.init(.designTime(), indexer: .init(),
                              scriptEngine: .init(workspace: .shared),
                              workspace: .shared),
                  selectedGroups: .constant([]),
                  selectedWorkflows: .constant([]),
                  focus: _focus) { _ in }
    }
  }

  static var focus: FocusState<Focus>?
  static var previews: some View {
      FocusWrapper()
      .frame(width: 960, height: 480)
  }
}
