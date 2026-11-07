import SwiftUI

extension ContentSplit {
  @Injectable
  struct ContentView: View {
    var content: some View {
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
    }
  }
}
