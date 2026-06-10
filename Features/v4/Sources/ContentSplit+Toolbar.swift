import SwiftUI

extension ContentSplit {
  struct Toolbar: ToolbarContent {
    var body: some ToolbarContent {
      ToolbarItem(placement: .confirmationAction) {
        AddWorkflow {}
      }
    }
  }
}
