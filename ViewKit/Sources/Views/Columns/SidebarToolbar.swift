import SwiftUI

struct SidebarToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: toggleSidebar,
             label: {
              Image(systemName: "sidebar.left")
                .renderingMode(.template)
                .foregroundColor(Color(.systemGray))
             })
        .help("Toggle Sidebar")
    }
  }

  func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(
      #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
}
