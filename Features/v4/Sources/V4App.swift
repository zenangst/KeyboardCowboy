import SwiftUI

@main
struct V4App: App {
  var body: some Scene {
    WindowGroup("v4") {
      ContentView()
        .frame(minWidth: 480, minHeight: 320)
    }
  }
}

private struct ContentView: View {
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "keyboard")
        .font(.system(size: 40))
      Text("Keyboard Cowboy")
        .font(.title2)
      Text("Launched from the Swift Package executable.")
        .foregroundStyle(.secondary)
    }
    .padding(32)
  }
}
