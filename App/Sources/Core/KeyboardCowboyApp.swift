import ApplicationServices
import AXEssibility
import Bonzai
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

@main
struct KeyboardCowboyApp: App {
#if DEBUG
  static func env() -> AppEnvironment {
    guard !isRunningPreview else { return .previews }

    if let override = ProcessInfo.processInfo.environment["APP_ENVIRONMENT_OVERRIDE"],
       let env = AppEnvironment(rawValue: override) {
      return env
    } else {
      return .production
    }
  }
#else
  static func env() -> AppEnvironment { .production }
#endif

  @FocusState var focus: AppFocus?
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private let windowOpener: WindowOpener
  private let coordinator: AppExtraCoordinator
  private var open: Bool = true
  private let core: Core
  @ObservedObject private var contentStore: ContentStore

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core
    self.windowOpener = WindowOpener(core: core)
    self.coordinator = AppExtraCoordinator(core: core, windowOpener: windowOpener)

    Task { @MainActor in
      InjectConfiguration.animation = .spring()
      Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
    }

    appDelegate.openWindow = windowOpener

    if launchArguments.isEnabled(.injection) { _ = InjectConfiguration.load }
  }

  var body: some Scene {
    AppMenuBarExtras(core: core, contentStore: core.contentStore, keyboardCleaner: core.keyboardCleaner,
                     onAction: { action in coordinator.handle(action) })
    .commands {
      CommandGroup(after: .appSettings) {
        AppMenu()
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
            core.contentCoordinator.handle(action)
            core.detailCoordinator.handle(action)
          },
          onNewGroup: {
            windowOpener.openGroup(.add(WorkflowGroup.empty()))
          },
          onNewWorkflow: {
            let action = ContentView.Action.addWorkflow(workflowId: UUID().uuidString)
            core.contentCoordinator.handle(action)
            core.detailCoordinator.handle(action)
            //            focus = .detail(.name)
          },
          onNewCommand: { id in
            windowOpener.openNewCommandWindow(.newCommand(workflowId: id))
          }
        )
        .environmentObject(core.contentStore.groupStore)
        .environmentObject(core.detailCoordinator.statePublisher)
        .environmentObject(core.detailCoordinator.infoPublisher)
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

    Settings { SettingsView().environmentObject(OpenPanelController()) }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
}
