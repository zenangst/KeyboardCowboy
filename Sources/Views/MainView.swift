import SwiftUI

struct MainView: View {
  @Binding var workflowGroups: [WorkflowGroup]
  @Binding var selection: Set<String>

  var body: some View {
    if workflowGroups.count > 1 {
      Text("Multiple groups selected")
    } else {
      ForEach(Array(workflowGroups)) { group in
        WorkflowListView(workflows: group.workflows,
                         selection: $selection)
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
        workflowGroups: .constant(store.groupStore.groups),
        selection: .constant([]))
    }
  }
}
