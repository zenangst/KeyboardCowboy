import SwiftUI

@main
struct KeyboardCowboy: App {
  @StateObject var store: Saloon = .init()

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
    }
  }
}
