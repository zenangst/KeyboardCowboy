import SwiftUI

struct MainView: View, Equatable {
  enum Action {
    case add
    case delete(Workflow)
  }
  var action: (Action) -> Void
  @Binding var groups: [WorkflowGroup]
  @Binding var selection: Set<String>

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()

  var body: some View {
    if groupIds.isEmpty {
      Text("No group selected")
    } else if groups.isEmpty {
      Text("No workflows in group")
    } else if groups.count > 1 {
      Text("Multiple groups selected")
    } else {
      ForEach(groups, id: \.self) { group in
        WorkflowListView(workflows: Binding<[Workflow]>(get: { group.workflows },
                                                        set: { _ in }),
                         selection: $selection,
                         action: { action in
          switch action {
          case .delete(let workflow):
            self.action(.delete(workflow))
          }
        })
          .navigationTitle(group.name)
          .navigationSubtitle("Workflows")
      }
    }
  }

  static func == (lhs: MainView, rhs: MainView) -> Bool {
    let result = lhs.groups == rhs.groups
    return result
  }
}

struct MainView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    VStack {
      MainView(
        action: { _ in },
        groups: .constant(store.groupStore.groups),
        selection: .constant([]))
    }
  }
}
