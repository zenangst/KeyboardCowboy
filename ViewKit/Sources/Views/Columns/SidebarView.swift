import SwiftUI

struct SidebarView: View {
  @ObservedObject var store: ViewKitStore

  var body: some View {
    GroupList(store: store)
      .toolbar(content: { SidebarToolbar() })
      .frame(minWidth: 225)
  }
}
