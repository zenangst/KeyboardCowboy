import SwiftUI
@_exported import Inject

@main
struct KeyboardCowboy: App {
  init() { Inject.animation = .easeInOut(duration: 0.175) }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .equatable()
    }
  }
}
