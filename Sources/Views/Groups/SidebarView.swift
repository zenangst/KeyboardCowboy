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
  @ObservedObject var configurationStore: ConfigurationStore
  @FocusState var focus: Focus?
  @ObservedObject var groupStore: GroupStore
  @ObservedObject var saloon: Saloon
  @Binding var sheet: Sheet?
  @Binding var selection: Set<String>

  var body: some View {
    VStack(alignment: .leading) {
      Label("Configuration", image: "")
        .labelStyle(HeaderLabelStyle())
        .padding([.leading, .trailing])
      ConfigurationSidebarView(configurationStore,
                               focus: _focus,
                               saloon: saloon)
      .padding([.leading, .trailing], 10)

      WorkflowGroupListView(
        appStore: appStore, groupStore: groupStore,
        selection: $selection, action: handleAction(_:))
      .sheet(item: $sheet, content: handleSheet(_:))
      .focused($focus, equals: .sidebar(.list))
    }
  }

  // MARK: Private methods

  private func handleAction(_ action: WorkflowGroupListView.Action) {
    switch action {
    case .edit(let group):
      sheet = .edit(group)
    case .delete(let group):
      groupStore.remove(group)
    }
  }

  @ViewBuilder
  private func handleSheet(_ sheet: SidebarView.Sheet) -> some View {
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
}

struct SidebarView_Previews: PreviewProvider {
  static var store = Saloon()
  static var previews: some View {
    SidebarView(appStore: ApplicationStore(),
                configurationStore: ConfigurationStore(),
                groupStore: store.groupStore,
                saloon: store,
                sheet: .constant(.none),
                selection: .constant([]))
  }
}
