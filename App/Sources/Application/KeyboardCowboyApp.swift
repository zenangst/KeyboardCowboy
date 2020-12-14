import SwiftUI
import ViewKit
import ModelKit

@main
struct KeyboardCowboyApp: App {
  @StateObject private var store = Saloon()
  @Environment(\.scenePhase) var scenePhase

  var body: some Scene {
    WindowGroup {
      store.state.currentView
        .frame(minWidth: 800, minHeight: 520)
        .onChange(of: scenePhase, perform: store.receive(_:))
    }
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      KeyboardCowboyCommands(store: store, keyInputSubject: Saloon.keyInputSubject)
    }

    Settings {
      KeyboardCowboySettingsView()
    }
  }
}
