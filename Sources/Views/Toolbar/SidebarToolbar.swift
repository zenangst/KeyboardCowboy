import SwiftUI

struct SidebarToolbar: ToolbarContent {
  enum Action {
    case addGroup
  }

  let configurationStore: ConfigurationStore
  @FocusState var focus: Focus?
  let saloon: Saloon
  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .status) {
      ConfigurationToolbarView(configurationStore,
                               focus: _focus,
                               saloon: saloon)
      Button(action: { action(.addGroup) }, label: {
        Image(systemName: "folder.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
      .help("Add new Group")
    }
  }
}
