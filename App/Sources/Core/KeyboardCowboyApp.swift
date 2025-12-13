import ApplicationServices
import AXEssibility
import Bonzai
import Cocoa
import Combine
@_exported import HotSwiftUI
import InputSources
import LaunchArguments
import SwiftUI

@main
struct KeyboardCowboyApp: App {
  @FocusState var focus: AppFocus?
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private var open: Bool = true

  private let windowOpener: WindowOpener
  private let coordinator: AppExtraCoordinator
  private let core: Core
  @ObservedObject private var contentStore: ContentStore

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core
    windowOpener = WindowOpener(core: core)
    coordinator = AppExtraCoordinator(core: core, windowOpener: windowOpener)

    guard !isRunningPreview else { return }

    Task { @MainActor in
      Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
    }

    appDelegate.openWindow = windowOpener
  }

  var body: some Scene {
    menuBarExtras()
    settings()
  }

  @SceneBuilder
  private func menuBarExtras() -> some Scene {
    AppMenuBarExtras(core: core, contentStore: core.contentStore, keyboardCleaner: core.keyboardCleaner,
                     onAction: { action in coordinator.handle(action) })
  }

  private func settings() -> some Scene {
    Settings {
      SettingsView()
        .defaultStyle()
        .environmentObject(OpenPanelController())
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
    .commands {
      CommandGroup(after: .appSettings) {
        AppMenu(modePublisher: KeyboardCowboyModePublisher(source: core.machPortCoordinator.$mode)) { newValue in
          if newValue {
            core.machPortCoordinator.startIntercept()
          } else {
            core.machPortCoordinator.disable()
          }
        }

        Button {
          windowOpener.openReleaseNotes()
        } label: { Text("What's new?") }
      }
      CommandGroup(replacing: .newItem) {
        FileMenu(
          onNewConfiguration: {
            let action = SidebarView.Action.addConfiguration(name: "New Configuration")
            core.configCoordinator.handle(action)
            core.sidebarCoordinator.handle(action)
            core.groupCoordinator.handle(action)
            core.workflowCoordinator.handle(action)
          },
          onNewGroup: {
            windowOpener.openGroup(.add(WorkflowGroup.empty()))
          },
          onNewWorkflow: {
            let action = GroupDetailView.Action.addWorkflow(workflowId: UUID().uuidString)
            core.groupCoordinator.handle(action)
            core.workflowCoordinator.handle(action)
            //            focus = .detail(.name)
          },
        )
        .environmentObject(core.configurationUpdater)
        .environmentObject(WindowOpener(core: core))
        .environmentObject(core.workflowCoordinator.updateTransaction)
        .environmentObject(core.shortcutStore)
        .environmentObject(core.contentStore.groupStore)
        .environmentObject(core.workflowCoordinator.statePublisher)
        .environmentObject(core.workflowCoordinator.infoPublisher)
        .environmentObject(core.raycast)
        .environmentObject(core.inputSourceStore)
      }

      CommandGroup(replacing: .toolbar) {
        ViewMenu(onFilter: {
          //          focus = .search
        })
      }

      CommandGroup(replacing: .help) {
        HelpMenu(onAction: coordinator.handleHelpMenu(_:))
      }
    }
  }
}

struct EmptyScene: Scene {
  var body: some Scene {
    WindowGroup { EmptyView() }.windowStyle(.hiddenTitleBar)
  }
}
