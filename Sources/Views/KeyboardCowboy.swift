import SwiftUI

@main
struct KeyboardCowboy: App {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject var store: Saloon = .init()

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
    }.onChange(of: scenePhase) { phase in
      if case .active = phase {
        store.applicationStore.reload()
      }
    }
  }
}
