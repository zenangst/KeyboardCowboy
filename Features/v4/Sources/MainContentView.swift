import HotSwiftUI
import SwiftUI

struct MainContentView: View {
  @ObserveInjection private var inject

  var body: some View {
    VStack {
      HStack {
        Image(systemName: "keyboard")
          .font(.system(size: 40))
        VStack(spacing: \.small) {
          Text("Keyboard Cowboy v4")
            .font(.title2)
          Text("Launched from the Swift Package executable.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }

      Divider()

      ButtonsScreen()
        .surface(.regularMaterial)
    }
    .surface(.regularMaterial)
    .frame(maxWidth: 400)
    .enableInjection()
  }
}
