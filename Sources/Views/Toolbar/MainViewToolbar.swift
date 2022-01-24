import SwiftUI

struct MainViewToolbar: ToolbarContent {
    var body: some ToolbarContent {
      ToolbarItemGroup(placement: .automatic) {
        Button(action: { },
        label: {
          Image(systemName: "rectangle.stack.badge.plus")
            .renderingMode(.template)
            .foregroundColor(Color(.systemGray))
        })
      }
    }
}
