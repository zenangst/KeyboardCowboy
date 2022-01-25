import SwiftUI

struct SidebarView: View {
  @ObservedObject var store: WorkflowGroupStore
  @Binding var selection: Set<String>

  var body: some View {
    WorkflowGroupListView(store: store,
                          selection: $selection,
                          action: { action in
      switch action {
      case .edit:
        break
      case .delete(let group):
        store.remove(group)
      }
    })
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    SidebarView(store: store.groupStore, selection: .constant([]))
  }
}
