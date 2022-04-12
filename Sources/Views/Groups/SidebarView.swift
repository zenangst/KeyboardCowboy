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

  @ObservedObject private var iO = Inject.observer
  @ObservedObject var appStore: ApplicationStore
  @ObservedObject var configurationStore: ConfigurationStore
  @FocusState var focus: Focus?
  @ObservedObject var groupStore: GroupStore
  @ObservedObject var contentStore: ContentStore
  @Binding var sheet: Sheet?
  @Binding var selection: Set<String>

  var body: some View {
    VStack(alignment: .leading) {
      Label("Configuration", image: "")
        .labelStyle(HeaderLabelStyle())
        .padding([.leading, .trailing])
      ConfigurationSidebarView(configurationStore,
                               contentStore: contentStore,
                               focus: _focus)
      .padding([.leading, .trailing, .bottom], 10)

      WorkflowGroupListView(
        appStore: appStore, groupStore: groupStore,
        selection: $selection, action: handleAction(_:))
      .sheet(item: $sheet, content: handleSheet(_:))
      .focused($focus, equals: .sidebar(.list))
    }
    .enableInjection()
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
  static var previews: some View {
    SidebarView(appStore: ApplicationStore(),
                configurationStore: ConfigurationStore(),
                groupStore: groupStore,
                contentStore: contentStore,
                sheet: .constant(.none),
                selection: .constant([]))
  }
}
