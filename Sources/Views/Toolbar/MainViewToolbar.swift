import SwiftUI

struct MainViewToolbar: ToolbarContent {
  enum Action {
    case add
  }
  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
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
