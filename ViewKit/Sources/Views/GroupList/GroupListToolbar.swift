import SwiftUI
import ModelKit

struct GroupListToolbar: ToolbarContent {
  let groupController: GroupController

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
      Button(action: {
        NSApp.tryToPerform(.showSidebar)
        groupController.perform(.createGroup)
      }, label: {
        Image(systemName: "folder.badge.plus")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
      .help("Add new Group")
    }
  }
}
