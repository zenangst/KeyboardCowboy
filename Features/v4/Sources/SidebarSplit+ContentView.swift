import SwiftUI

extension SidebarSplit {
  @Injectable
  struct ContentView: View {
    var content: some View {
      VStack(spacing: \.extraLarge) {
        Configurations()
        ScrollView {
          Groups()
        }
        UserModes()
      }
      .surface()
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .toolbar { Toolbar() }
    }
  }
}
