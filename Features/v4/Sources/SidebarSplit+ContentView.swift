import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct ContentView: View {
    @ObserveInjection private var inject
    var body: some View {
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
      .enableInjection()
    }
  }
}
