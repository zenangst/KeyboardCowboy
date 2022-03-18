import SwiftUI

struct MainView: View {
  enum Action {
    case add
    case delete(Workflow)
  }
  var action: (Action) -> Void
  let applicationStore: ApplicationStore
  @FocusState var focus: Focus?
  @StateObject var store: GroupStore
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
      Group {
        ForEach($store.selectedGroups) { group in
          WorkflowListView(applicationStore: applicationStore,
                           store: store, workflows: group.workflows,
                           selection: $selection, action: handle(_:))
          .equatable()
          .navigationTitle(group.name.wrappedValue)
          .navigationSubtitle("Workflows")
        }
      }
      .focused($focus, equals: .main(.groupComponent))
    }
  }

  // MARK: Private methods

  private func handle(_ action: WorkflowListView.Action) {
    switch action {
    case .delete(let workflow):
      self.action(.delete(workflow))
    }
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      MainView(
        action: { _ in },
        applicationStore: ApplicationStore(),
        store: groupStore,
        selection: .constant([]))
    }
  }
}
