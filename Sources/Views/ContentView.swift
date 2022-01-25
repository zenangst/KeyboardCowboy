import SwiftUI

struct ContentView: View {
  @StateObject var store: Saloon

  @Binding private var selectedGroups: [WorkflowGroup]
  @Binding private var selectedWorkflows: [Workflow]

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") private var workflowIds = Set<String>()

  init(store: Saloon) {
    _store = .init(wrappedValue: store)
    _selectedGroups = .init(get: { store.selectedGroups },
                            set: { store.selectedGroups = $0 })
    _selectedWorkflows = .init(get: { store.selectedWorkflows },
                               set: { store.selectedWorkflows = $0 })
  }

  var body: some View {
    NavigationView {
      SidebarView(
        appStore: store.applicationStore,
        groupStore: store.groupStore,
        selection: $groupIds)
        .toolbar(content: {
          SidebarToolbar { action in
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
        })
        .frame(minWidth: 200)
        // Handle group id updates.
        .onChange(of: groupIds) { groupIds in
          store.selectedGroupIds = Array(groupIds)
          store.selectedGroups = store.groupStore.groups.filter({ groupIds.contains($0.id) })
          store.groupStore.selectedGroupIds = Array(groupIds)
          if let firstGroup = store.selectedGroups.first,
             let firstWorkflow = firstGroup.workflows.first {
            workflowIds = [firstWorkflow.id]
          } else {
            workflowIds = []
          }
        }

      MainView(
        action: { action in
          switch action {
          case .add:
            break
          case .delete(let workflow):
            store.groupStore.remove(workflow)
          }
        },
        groups: $store.selectedGroups,
        selection: $workflowIds)
        .toolbar(content: {
          MainViewToolbar { action in
            switch action {
            case .add:
              let workflow = Workflow.empty()
              store.groupStore.add(workflow)
            }
          }
        })
        // Handle selection updates on workflows
        .onChange(of: workflowIds) { workflowIds in
          store.selectedWorkflows = store.selectedGroups
            .flatMap({ $0.workflows })
            .filter({ workflowIds.contains($0.id) })
        }

      DetailView(workflows: $store.selectedWorkflows)
        .toolbar(content: { DetailToolbar() })
        // Handle workflow updates
        .onChange(of: selectedWorkflows,
                  perform: { foo in
          store.groupStore.receive(foo)
        })
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
