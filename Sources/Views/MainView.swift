import SwiftUI

struct MainView: View {
  @Binding var workflowGroups: Set<WorkflowGroup>
  @Binding var selection: Set<Workflow>

  var body: some View {
    if workflowGroups.count > 1 {
      Text("Multiple groups selected")
    } else {
      ForEach(Array(workflowGroups), id: \.id) { group in
        WorkflowListView(workflows: group.workflows, selection: $selection)
          .navigationTitle(group.name)
          .navigationSubtitle("Workflows")
      }
    }
  }
}

struct MainView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    VStack {
      MainView(
        workflowGroups: .init(get: { store.selectedGroups },
                              set: { store.selectedGroups = $0 }),
        selection: .constant([]))
    }
  }
}
