import SwiftUI

struct MainView: View {
  enum Action {
    case add
    case delete(Workflow)
  }
  var action: (Action) -> Void
  @ObservedObject var store: WorkflowGroupStore
  @Binding var selection: Set<String>

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()

  var body: some View {
    if groupIds.isEmpty {
      Text("No group selected")
    } else if store.groups.isEmpty {
      Text("No workflows in group")
    } else if groupIds.count > 1 {
      Text("Multiple groups selected")
    } else {
      ForEach($store.selectedGroups) { group in
        WorkflowListView(workflows: group.workflows,
                         selection: $selection,
                         action: { action in
          switch action {
          case .delete(let workflow):
            self.action(.delete(workflow))
          }
        })
          .navigationTitle(group.name.wrappedValue)
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
        action: { _ in },
        store: store.groupStore,
        selection: .constant([]))
    }
  }
}
