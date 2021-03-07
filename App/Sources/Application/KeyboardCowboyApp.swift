import SwiftUI
import ViewKit
import ModelKit
import Introspect

@main
struct KeyboardCowboyApp: App {
  @StateObject private var store = Saloon()
  @State var applicationIsActive: Bool = false

  var body: some Scene {
    WindowGroup {
      if applicationIsActive {
        $store.state.wrappedValue.currentView
          .frame(minWidth: 800, minHeight: 520)
      } else {
        ZStack {}
          .onReceive(store.$state, perform: {
            applicationIsActive = $0.currentView != nil
          })
          .frame(minWidth: 800, minHeight: 0)
      }
    }
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      KeyboardCowboyCommands(
        store: store,
        keyInputSubject: Saloon.keyInputSubject,
        selectedGroup: $store.selectedGroup,
        selectedWorkflow: $store.selectedWorkflow,
        newWorkflowAction: {
          if let group = $store.selectedGroup.wrappedValue {
            store.context.workflows.perform(.create(groupId: group.id))
          }
        })
    }
    Settings {
      KeyboardCowboySettingsView()
    }
  }
}
