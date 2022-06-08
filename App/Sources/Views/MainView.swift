import SwiftUI

struct MainView: View {
  @ObserveInjection var inject
  enum Action {
    case add
    case delete(Workflow)
  }
  var action: (Action) -> Void
  let applicationStore: ApplicationStore
  @FocusState var focus: Focus?
  @StateObject var store: GroupStore
  @Binding var selection: Set<String>
  @State private var groupIds: Set<String> = Set<String>(AppStorageStore().groupIds)

  var body: some View {
    if groupIds.isEmpty {
      Text("No group selected")
        .enableInjection()
    } else if store.groups.isEmpty {
      Text("No workflows in group")
        .enableInjection()
    } else if groupIds.count > 1 {
      Text("Multiple groups selected")
        .enableInjection()
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
      .enableInjection()
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
