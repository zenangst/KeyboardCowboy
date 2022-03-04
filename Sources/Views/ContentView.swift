import SwiftUI

struct ContentView: View, Equatable {
  static func ==(lhs: ContentView, rhs: ContentView) -> Bool {
    return true
  }
  @StateObject var store: Saloon

  @Binding private var selectedGroups: [WorkflowGroup]
  @Binding private var selectedWorkflows: [Workflow]

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") private var workflowIds = Set<String>()

  @FocusState private var focus: Focus?

  init(store: Saloon) {
    _store = .init(wrappedValue: store)
    _selectedGroups = .init(get: { store.groupStore.selectedGroups },
                            set: { store.groupStore.selectedGroups = $0 })
    _selectedWorkflows = .init(get: { store.selectedWorkflows },
                               set: { store.selectedWorkflows = $0 })

    focus = .main(.groupComponent)
  }

  var body: some View {
    NavigationView {
      SidebarView(appStore: store.applicationStore,
                  configurationStore: store.configurationStore,
                  focus: _focus,
                  groupStore: store.groupStore,
                  saloon: store,
                  selection: $groupIds)
      .toolbar {
        SidebarToolbar(configurationStore: store.configurationStore,
                       focus: _focus,
                       saloon: store,
                       action: handleSidebar(_:))
      }
      .frame(minWidth: 280, idealWidth: 310)
      .onChange(of: groupIds, perform: { store.selectGroups($0) })

      MainView(action: handleMainAction(_:),
               applicationStore: store.applicationStore,
               focus: _focus, store: store.groupStore, selection: $workflowIds)
      .toolbar { MainViewToolbar(action: handleToolbarAction(_:)) }
      .frame(minWidth: 270)
      .onChange(of: workflowIds, perform: { store.selectWorkflows($0) })

      DetailView(applicationStore: store.applicationStore,
                 focus: _focus, workflows: $store.selectedWorkflows)
      .equatable()
      .toolbar { DetailToolbar(action: handleDetailToolbarAction(_:)) }
      // Handle workflow updates
      .onChange(of: selectedWorkflows, perform: { workflows in
        store.updateWorkflows(workflows)
      })
      .frame(minWidth: 360, minHeight: 400)
    }
    .searchable(text: .constant(""))
  }

  // MARK: Private methods

  private func handleSidebar(_ action: SidebarToolbar.Action) {
    switch action {
    case .addGroup:
      let group = WorkflowGroup.empty()
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
      focus = .detail(.info(workflow))
    }
  }

  private func handleDetailToolbarAction(_ action: DetailToolbar.Action) {
    switch action {
    case .addCommand:
      guard !selectedWorkflows.isEmpty else { return }
      selectedWorkflows[0].commands.append(.keyboard(.init(keyboardShortcut: .init(key: "A"))))
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    ContentView(store: store)
      .frame(width: 960, height: 480)
  }
}
