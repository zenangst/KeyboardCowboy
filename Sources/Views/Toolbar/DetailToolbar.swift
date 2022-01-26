import SwiftUI

struct DetailToolbar: ToolbarContent {
  enum Action {
    case addCommand
  }

  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: { action(.addCommand) },
             label: {
        Image(systemName: "plus.square.dashed")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
    }
  }
}
