import SwiftUI

@Injectable
struct MainContentView: View {

  var content: some View {
    NavigationSplitView(sidebar: {
      SidebarSplit.ContentView()
    }, content: {
      ContentSplit.ContentView()
    }, detail: {
      DetailSplit.ContentView()
    })
  }
}
