import SwiftUI

struct SidebarView: View {
  @ObservedObject var store: ViewKitStore

  @Binding var selection: String?
  @Binding var workflowSelection: String?

  var body: some View {
    GroupList(store: store, selection: $selection,
              workflowSelection: $workflowSelection)
      .toolbar(content: { SidebarToolbar() })
      .frame(minWidth: 225)
  }
}
