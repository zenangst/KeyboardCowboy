import SwiftUI
import ViewKit
import ModelKit
import Introspect

@main
struct KeyboardCowboyApp: App {
  @StateObject private var store = Saloon()
  @Environment(\.scenePhase) var scenePhase
  @State private var appState: ApplicationState = .launching
  @State private var minWidth: CGFloat = 0
  @State private var minHeight: CGFloat = 0

  var body: some Scene {
    WindowGroup {
      Unwrap(appState, content: { state in
        state.currentView
      })
      .onChange(of: scenePhase, perform: {
        store.receive($0)
      })
      .onReceive(store.$state, perform: { value in
        minWidth = 800
        minHeight = 520
        appState = value
      })
      .frame(minWidth: minWidth, minHeight: minHeight)
    }
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      KeyboardCowboyCommands(store: store,
                             keyInputSubject: Saloon.keyInputSubject,
                             selectedGroup: $store.selectedGroup,
                             selectedWorkflow: $store.selectedWorkflow)
    }

    Settings {
      KeyboardCowboySettingsView()
    }
  }
}
