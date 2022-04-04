import SwiftUI
@_exported import Inject

@main
struct KeyboardCowboy: App {
  init() { Inject.load }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .equatable()
    }
  }
}
