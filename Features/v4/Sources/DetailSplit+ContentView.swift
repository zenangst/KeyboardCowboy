import HotSwiftUI
import SwiftUI

extension DetailSplit {
  struct ContentView: View {
    @ObserveInjection private var inject
    var body: some View {
      ScrollView {
        VStack {
          HStack(spacing: \.medium) {
            SymbolImage("keyboard")
              .frame(height: 16)
              .surface(.thickMaterial)

            VStack(spacing: \.none) {
              Text("Keyboard Cowboy v4")
                .font(.title2)
              Text("Launched from the Swift Package executable.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: {}, label: {
              SymbolImage("xmark")
                .frame(width: 10, height: 10)
            })
            .frame(width: 24, height: 24)
          }

          Divider()

          ButtonsScreen()
        }
        .surface()
      }
      .toolbar { Toolbar() }
      .enableInjection()
    }
  }
}
