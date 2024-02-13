import Bonzai
import SwiftUI

struct MainWindow: Scene {
  private let core: Core
  @FocusState var focus: AppFocus?

  @Environment(\.openWindow) private var openWindow
  private let onScene: (AppScene) -> Void

  init(_ core: Core, onScene: @escaping (AppScene) -> Void) {
    self.core = core
    self.onScene = onScene
  }

  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.mainWindowIdentifier) {
      MainWindowView($focus, core: core, onSceneAction: {
        onScene($0)
      })
      .environmentObject(ApplicationStore.shared)
      .environmentObject(core.contentStore)
      .environmentObject(core.groupStore)
      .environmentObject(core.shortcutStore)
      .environmentObject(core.recorderStore)
      .environmentObject(core.configCoordinator.configurationsPublisher)
      .environmentObject(core.configCoordinator.configurationPublisher)
      .environmentObject(core.sidebarCoordinator.publisher)
      .environmentObject(core.contentCoordinator.contentPublisher)
      .environmentObject(core.contentCoordinator.groupPublisher)
      .environmentObject(core.detailCoordinator.statePublisher)
      .environmentObject(core.detailCoordinator.infoPublisher)
      .environmentObject(core.detailCoordinator.triggerPublisher)
      .environmentObject(core.detailCoordinator.commandsPublisher)
      .environmentObject(OpenPanelController())
      .animation(.easeInOut, value: core.contentStore.state)
      .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
      .onDisappear {
        Task { await IconCache.shared.clearCache() }
      }
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .commands {
      CommandGroup(after: .appSettings) {
        AppMenu()
        Button { openWindow(id: KeyboardCowboy.releaseNotesWindowIdentifier) } label: { Text("What's new?") }
      }
      CommandGroup(replacing: .newItem) {
        FileMenu(
          onNewConfiguration: {
            let action = SidebarView.Action.addConfiguration(name: "New Configuration")
            core.configCoordinator.handle(action)
            core.sidebarCoordinator.handle(action)
            core.contentCoordinator.handle(action)
            core.detailCoordinator.handle(action)
          },
          onNewGroup: { onScene(.addGroup) },
          onNewWorkflow: {
            let action = ContentListView.Action.addWorkflow(workflowId: UUID().uuidString)
            core.contentCoordinator.handle(action)
            core.detailCoordinator.handle(action)
            focus = .detail(.name)
          }
        )
        .environmentObject(core.contentStore.groupStore)
      }

      CommandGroup(replacing: .toolbar) {
        ViewMenu(onFilter: {
          focus = .search
        })
      }

      CommandGroup(replacing: .help) {
        HelpMenu()
      }
    }
  }
}
