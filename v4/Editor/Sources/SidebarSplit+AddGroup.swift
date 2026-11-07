import SwiftUI

extension SidebarSplit {
  @Injectable
  struct AddGroup: View {

    let action: () -> Void

    var content: some View {
      Button(action: action, label: {
        SwiftUI.Label(title: { Text("Add Group") }, icon: {
          Image(systemName: "folder.badge.plus")
        })
      })
      .labelStyle(.iconOnly)
    }
  }
}
