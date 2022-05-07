import SwiftUI

struct ContentView: View, Equatable {
  enum Action {
    case reveal(Command)
    case run(Command)
  }
  @ObserveInjection var inject

  @StateObject var store: ContentStore

  @State var detailViewSheet: WorkflowView.Sheet?
  @State var sidebarViewSheet: SidebarView.Sheet?
  @State private var searchQuery: String

  @Binding private var selectedGroups: [WorkflowGroup]
  @Binding private var selectedWorkflows: [Workflow]

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") private var workflowIds = Set<String>()

  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.undoManager) private var undoManager

  private var action: (Action) -> Void
  @FocusState private var focus: Focus?

  init(_ store: ContentStore, action: @escaping (Action) -> Void) {
    _store = .init(wrappedValue: store)
    _selectedGroups = .init(get: { store.groupStore.selectedGroups },
                            set: { store.groupStore.selectedGroups = $0 })
    _selectedWorkflows = .init(get: { store.selectedWorkflows },
                               set: { store.selectedWorkflows = $0 })
    _searchQuery = .init(initialValue: "")
    self.action = action
    focus = .main(.groupComponent)
  }

  var body: some View {
    NavigationView {
      SidebarView(appStore: store.applicationStore,
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
      .onChange(of: groupIds, perform: { store.selectGroupsIds($0) })

      MainView(action: handleMainAction(_:),
               applicationStore: store.applicationStore,
               focus: _focus, store: store.groupStore, selection: $workflowIds)
      .toolbar { MainViewToolbar(action: handleToolbarAction(_:)) }
      .frame(minWidth: 270)
      .onChange(of: workflowIds, perform: { workflowIds in
        store.selectWorkflowIds(workflowIds)
      })

      DetailView(applicationStore: store.applicationStore,
                 recorderStore: store.recorderStore,
                 shortcutStore: store.shortcutStore, 
                 focus: _focus,
                 workflows: $store.selectedWorkflows,
                 sheet: $detailViewSheet,
                 action: handleDetailAction(_:))
      .equatable()
      .toolbar { DetailToolbar(action: handleDetailToolbarAction(_:)) }
      // Handle workflow updates
      .onChange(of: selectedWorkflows, perform: { workflows in
        store.updateWorkflows(workflows)
      })
      .frame(minWidth: 380, minHeight: 417)
    }
    .searchable(text: $searchQuery)
    .onChange(of: scenePhase) { phase in
      guard case .active = phase else { return }
      store.applicationStore.reload()
      store.undoManager = undoManager
    }
    .enableInjection()
  }

  static func ==(lhs: ContentView, rhs: ContentView) -> Bool {
    return true
  }

  // MARK: Private methods

  private func handleSidebar(_ action: SidebarToolbar.Action) {
    switch action {
    case .addGroup:
      let group = WorkflowGroup.empty()
      sidebarViewSheet = .edit(group)
      store.groupStore.add(group)
      groupIds = [group.id]
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

  private func handleDetailAction(_ action: DetailView.Action) -> Void {
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

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(.init(.designTime())) { _ in }
      .frame(width: 960, height: 480)
  }
}
