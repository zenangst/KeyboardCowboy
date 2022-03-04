import SwiftUI

struct SidebarToolbar: ToolbarContent {
  enum Action {
    case addGroup
    case toggleSidebar
  }

  let configurationStore: ConfigurationStore
  @FocusState var focus: Focus?
  let saloon: Saloon
  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .status) {
      Button(action: { action(.toggleSidebar) },
             label: {
        Image(systemName: "sidebar.left")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
      .help("Toggle Sidebar")

      Button(action: { action(.addGroup) }, label: {
        Image(systemName: "folder.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
      .help("Add new Group")
    }
  }
}
