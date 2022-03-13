import SwiftUI

struct DetailToolbar: ToolbarContent {
  enum Action {
    case addCommand
  }

  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        withAnimation(.interactiveSpring()) {
          action(.addCommand)
        }
      },
             label: {
        Label(title: {
          Text("Add command")
        }, icon: {
          Image(systemName: "plus.square.dashed")
            .renderingMode(.template)
            .foregroundColor(Color(.systemGray))
        })
      })
    }
  }
}
