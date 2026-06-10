import HotSwiftUI
import SwiftUI

extension ContentSplit {
  struct ContentView: View {
    @ObserveInjection private var inject

    var body: some View {
      ScrollView {
        VStack {
          Button(action: {}, label: {
            Text("Item")
              .frame(maxWidth: .infinity, alignment: .leading)
              .surface()
          })
        }
        .surface()
      }
      .navigationTitle(.constant("Global"))
      .navigationSubtitle("Workflows")
      .toolbar { Toolbar() }
      .enableInjection()
    }
  }
}
