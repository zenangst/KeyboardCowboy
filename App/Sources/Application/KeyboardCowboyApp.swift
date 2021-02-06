import SwiftUI
import ViewKit
import ModelKit
import Introspect

@main
struct KeyboardCowboyApp: App {
  @StateObject private var store = Saloon()
  @State private var applicationState: ApplicationState = .launching
  @State private var minWidth: CGFloat = 0
  @State private var minHeight: CGFloat = 0

  var body: some Scene {
    WindowGroup {
      Unwrap(applicationState) {
        $0.currentView
      }
      .onReceive(store.$state, perform: { value in
        guard !isRunningPreview else { return }
        minWidth = 800
        minHeight = 520
        applicationState = value
      })
      .frame(minWidth: minWidth,
             minHeight: minHeight,
             alignment: .center)
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
