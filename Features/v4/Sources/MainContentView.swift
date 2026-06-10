import HotSwiftUI
import SwiftUI

struct MainContentView: View {
  @ObserveInjection private var inject

  var body: some View {
    VStack {
      Image(systemName: "keyboard")
        .font(.system(size: 40))
      VStack {
        VStack {
          Text("Keyboard Cowboy v4")
            .font(.title2)
          Text("Launched from the Swift Package executable.")
            .foregroundStyle(.secondary)
        }
        .surface(.regularMaterial)
      }
      .surface(.thinMaterial)

      ButtonsScreen()
        .surface(.regularMaterial)
    }
    .enableInjection()
  }
}
