import HotSwiftUI
import SwiftUI

struct MainContentView: View {
  @ObserveInjection private var inject

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "keyboard")
        .font(.system(size: 40))
      Text("Keyboard Cowboy v4")
        .font(.title2)
      Text("Launched from the Swift Package executable.")
        .foregroundStyle(.secondary)
    }
    .padding(32)
    .enableInjection()
  }
}
