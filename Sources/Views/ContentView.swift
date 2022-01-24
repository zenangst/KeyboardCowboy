import SwiftUI

struct ContentView: View {
  @StateObject var store: Saloon
  @Binding var selectedGroups: [WorkflowGroup]
  @Binding var selectedWorkflows: [Workflow]

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
      SidebarView(store: store.groupStore,
                  selection: $groupIds)
        .toolbar(content: { SidebarToolbar() })
        .frame(minWidth: 200)
        .onChange(of: groupIds) { groupIds in
          selectedGroups = store.groupStore.groups.filter({ groupIds.contains($0.id) })
          if let firstGroup = selectedGroups.first,
             let firstWorkflow = firstGroup.workflows.first {
            workflowIds = [firstWorkflow.id]
          } else {
            workflowIds = []
          }
        }

      MainView(workflowGroups: $selectedGroups,
               selection: $workflowIds)
        .toolbar(content: { MainViewToolbar() })
        .frame(minWidth: 240)
        .onChange(of: workflowIds) { workflowIds in
          selectedWorkflows = selectedGroups
            .flatMap({ $0.workflows })
            .filter({ workflowIds.contains($0.id) })
        }

      DetailView(workflows: $selectedWorkflows)
        .toolbar(content: { DetailToolbar() })
        .onChange(of: selectedWorkflows,
                  perform: { store.receive($0) })
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
