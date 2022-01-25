import SwiftUI

struct WorkflowGroupListView: View {
  enum Action {
    case edit(WorkflowGroup)
    case delete(WorkflowGroup)
  }
  @ObservedObject var store: WorkflowGroupStore
  @Binding var selection: Set<String>

  let action: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      Label("Groups", image: "")
        .labelStyle(HeaderLabelStyle())
        .padding(.leading)
      List(store.groups, selection: $selection) { group in
        WorkflowGroupView(group: group)
          .contextMenu { contextMenu(group) }
          .id(group.id)
      }
      .listStyle(SidebarListStyle())
    }
  }

  func contextMenu(_ group: WorkflowGroup) -> some View {
    VStack {
      Button("Info", action: {
        action(.edit(group))
      })
      Divider()
      Button("Delete", action: {
        action(.delete(group))
      })
    }
  }
}

struct WorkflowGroupListView_Previews: PreviewProvider {
  static let store = Saloon()
  static var previews: some View {
    WorkflowGroupListView(store: store.groupStore,
                          selection: .constant([]),
                          action: { _ in })
  }
}
