import HotSwiftUI
import SwiftUI

struct MainContentView: View {
  @ObserveInjection private var inject

  var body: some View {
    NavigationSplitView(sidebar: {
      SidebarSplit.ContentView()
    }, content: {
      ContentSplit.ContentView()
    }, detail: {
      DetailSplit.ContentView()
    })
    .enableInjection()
  }
}
