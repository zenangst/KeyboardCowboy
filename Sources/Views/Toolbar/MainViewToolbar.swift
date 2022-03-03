import SwiftUI

struct MainViewToolbar: ToolbarContent {
  enum Action {
    case add
    case toggleSidebar
  }
  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
      Button(action: { action(.toggleSidebar) },
             label: {
        Image(systemName: "sidebar.left")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
        .help("Toggle Sidebar")

      Button(action: { action(.add) },
             label: {
        Image(systemName: "rectangle.stack.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
        .opacity(!groupIds.isEmpty ? 1.0 : 0.5)
        .disabled(groupIds.isEmpty)
    }
  }
}
