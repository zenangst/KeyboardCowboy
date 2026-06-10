import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct AddGroup: View {
    @ObserveInjection private var inject

    let action: () -> Void

    var body: some View {
      Button(action: action, label: {
        SwiftUI.Label(title: { Text("Add Group") }, icon: {
          Image(systemName: "folder.badge.plus")
        })
      })
      .labelStyle(.iconOnly)
      .enableInjection()
    }
  }
}
