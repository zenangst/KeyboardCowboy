import SwiftUI

extension SidebarSplit {
  struct Toolbar: ToolbarContent {
    var body: some ToolbarContent {
      ToolbarItem {
        AddGroup {}
      }
    }
  }
}
