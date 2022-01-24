import SwiftUI

struct WorkflowGroupListView: View {
  @ObservedObject var store: WorkflowGroupStore
  @Binding var selection: Set<String>

  var body: some View {
    VStack(alignment: .leading) {
      Label("Groups", image: "")
        .labelStyle(HeaderLabelStyle())
        .padding(.leading)
      List(store.groups, selection: $selection) { group in
        WorkflowGroupView(group: group)
          .id(group.id)
      }
      .listStyle(SidebarListStyle())
    }
  }
}

struct WorkflowGroupListView_Previews: PreviewProvider {
  static let store = Saloon()
  static var previews: some View {
    WorkflowGroupListView(store: store.groupStore,
                          selection: .constant([]))
  }
}
