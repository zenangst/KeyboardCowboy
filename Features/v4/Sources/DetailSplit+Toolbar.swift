import HotSwiftUI
import SwiftUI

extension DetailSplit {
  struct Toolbar: ToolbarContent {
    var body: some ToolbarContent {
      ToolbarItem(placement: .destructiveAction) {
        TextField(text: .constant("confirmationAction"), label: {
          Text("Workflow name")
        })
        .frame(minWidth: 300)
      }

      ToolbarItem(placement: .principal) {
        Spacer()
      }
      ToolbarItem(placement: .confirmationAction) {
        EnableButton()
      }
    }
  }
}
