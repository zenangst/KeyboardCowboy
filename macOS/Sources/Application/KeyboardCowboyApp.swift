import SwiftUI
import ViewKit
import ModelKit
import Introspect
import Combine

@main
struct KeyboardCowboyApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var store = Saloon()

  var body: some Scene {
    WindowGroup {
      $store.view.wrappedValue
        .onChange(of: scenePhase, perform: store.scenePhaseChanged(_:))
    }
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
