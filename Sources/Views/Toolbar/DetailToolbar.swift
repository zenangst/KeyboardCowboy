import SwiftUI

struct DetailToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Spacer()
      Button(action: { },
             label: {
        Image(systemName: "rectangle.stack.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
    }
  }
}
