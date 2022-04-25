import SwiftUI

struct MainViewToolbar: ToolbarContent {
  @ObserveInjection var inject
  enum Action {
    case add
  }
  var action: (Action) -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
      Button(action: { action(.add) },
             label: {
        Label(title: {
          Text("Add workflow")
        }, icon: {
          Image(systemName: "rectangle.stack.badge.plus")
            .renderingMode(.template)
            .foregroundColor(Color(.systemGray))
        })
      })
      .enableInjection()
    }
  }
}
