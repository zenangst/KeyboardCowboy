import SwiftUI

struct SidebarView: View {
  enum Sheet: Identifiable {
    case edit(WorkflowGroup)

    var id: String {
      switch self {
      case .edit:
        return "edit"
      }
    }
  }

  @ObservedObject var appStore: ApplicationStore
  @FocusState var focus: Focus?
  @ObservedObject var groupStore: GroupStore
  @State var sheet: Sheet?
  @Binding var selection: Set<String>

  var body: some View {
    WorkflowGroupListView(
      appStore: appStore,
      groupStore: groupStore,
      selection: Binding<Set<String>>(get: {
        selection
      }, set: {
        selection = $0
        focus = .main(.groupComponent)
      }),
      action: { action in
      switch action {
      case .edit(let group):
        sheet = .edit(group)
      case .delete(let group):
        groupStore.remove(group)
      }
    })
    .sheet(item: $sheet) { sheet in
      switch sheet {
      case .edit(let group):
        EditWorfklowGroupView(applicationStore: appStore, group: group) { action in
          self.sheet = nil
          switch action {
          case .ok(let group):
            groupStore.receive([group])
          case .cancel:
            break
          }
        }
      }
    }
    .focused($focus, equals: .sidebar)
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    SidebarView(appStore: ApplicationStore(),
                groupStore: store.groupStore,
                selection: .constant([]))
  }
}
