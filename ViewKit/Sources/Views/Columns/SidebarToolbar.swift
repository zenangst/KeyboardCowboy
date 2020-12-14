import SwiftUI

struct SidebarToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: { NSApp.tryToPerform(.toggleSidebar) },
             label: {
              Image(systemName: "sidebar.left")
                .renderingMode(.template)
                .foregroundColor(Color(.systemGray))
             })
        .help("Toggle Sidebar")
    }
  }
}
