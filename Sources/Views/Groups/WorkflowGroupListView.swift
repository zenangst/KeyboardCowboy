import SwiftUI

struct WorkflowGroupListView: View {
  @ObservedObject var store: WorkflowGroupStore
  @Binding var selection: Set<WorkflowGroup>

  var body: some View {
    VStack(alignment: .leading) {
      Label("Groups", image: "")
        .labelStyle(HeaderLabelStyle())
        .padding(.leading)
      List(store.groups, id: \.self,
           selection: $selection,
           rowContent: WorkflowGroupView.init)
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
