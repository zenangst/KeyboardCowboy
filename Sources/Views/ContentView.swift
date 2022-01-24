import SwiftUI

struct ContentView: View {
  @StateObject var store: Saloon
  @Binding var selectedGroups: Set<WorkflowGroup>
  @Binding var selectedWorkflows: Set<Workflow>

  @AppStorage("selectedGroupIds") private var groupIds = [String]()
  @AppStorage("selectedWorkflowIds") private var workflowIds = [String]()

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
                  selection: $selectedGroups)
        .onChange(of: selectedGroups) { groups in
          groupIds = groups.compactMap({ $0.id })

          if let firstGroup = groups.first,
             let firstWorkflow = firstGroup.workflows.first {
            selectedWorkflows = [firstWorkflow]
          } else {
            selectedWorkflows = []
          }
        }
        .toolbar(content: { SidebarToolbar() })
        .frame(minWidth: 200)

      MainView(workflowGroups: $selectedGroups,
               selection: $selectedWorkflows)
        .onChange(of: selectedWorkflows) { workflows in
          workflowIds = workflows.compactMap({ $0.id })
        }
        .toolbar(content: { MainViewToolbar() })
        .frame(minWidth: 240)

      DetailView(workflows: $selectedWorkflows)
        .toolbar(content: { DetailToolbar() })
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
