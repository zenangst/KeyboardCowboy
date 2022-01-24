import SwiftUI

struct SidebarToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
      Button(action: {  },
             label: {
        Image(systemName: "sidebar.left")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
        .help("Toggle Sidebar")

      Button(action: {  }, label: {
        Image(systemName: "folder.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
        .help("Add new Group")
    }
  }
}
