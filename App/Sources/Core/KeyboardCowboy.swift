import ApplicationServices
import Bonzai
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

@main
struct KeyboardCowboy: App {
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
  @Namespace var namespace
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private var open: Bool = true
  private let core: Core
  @ObservedObject var contentStore: ContentStore

  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core

    Task {
      await MainActor.run {
        Inject.animation = .spring()
        Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
      }
    }

    if launchArguments.isEnabled(.injection) { _ = Inject.load }
  }

  var body: some Scene {
    AppMenuBar(onAction:  { action in
      guard !launchArguments.isEnabled(.runningUnitTests) else { return }
      switch action {
      case .onAppear:
        if KeyboardCowboy.env() == .development {
          handleScene(.mainWindow)
        } else {
          if !AXIsProcessTrustedWithOptions(nil) {
            handleScene(.permissions)
            return
          }
        }
      case .openMainWindow:
        handleScene(.mainWindow)
      case .reveal:
        NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
      }
    })

    Settings {
      TabView {
        ApplicationSettingsView()
          .tabItem { Label("Applications", systemImage: "appclip") }
        NotificationsSettingsView()
          .tabItem { Label("Notifications", systemImage: "app.badge") }
        PermissionsSettings()
          .tabItem { Label("Permissions", systemImage: "hand.raised.circle.fill") }
      }
      .environmentObject(OpenPanelController())
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)

    WindowGroup(id: KeyboardCowboy.permissionsSettingsWindowIdentifier) {
      PermissionsSettings()
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)

    WindowGroup(id: KeyboardCowboy.mainWindowIdentifier) {
      MainWindowView($focus, core: core, onSceneAction: {
        handleScene($0)
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
          onNewGroup: { handleScene(.addGroup) },
          onNewWorkflow: {
            let action = ContentListView.Action.addWorkflow(workflowId: UUID().uuidString)
            core.contentCoordinator.handle(action)
            core.detailCoordinator.handle(action)
            focus = .detail(.name)
          }
        )
        .environmentObject(contentStore.groupStore)
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

    PermissionsScene { action in
      switch action {
      case .github:
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy")!)
      case .requestPermissions:
        NSApplication.shared.keyWindow?.close()
        openWindow(id: KeyboardCowboy.permissionsSettingsWindowIdentifier)
        AccessibilityPermission.shared.requestPermission()
      }
    }

    NewCommandWindow(contentStore: core.contentStore, configurationPublisher: core.configCoordinator.configurationPublisher) { workflowId, commandId, title, payload in
      let groupIds = core.groupSelectionManager.selections
      Task {
        await core.detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                               title: title, commandId: commandId)
        core.contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId], groupIds: groupIds))
        core.contentCoordinator.handle(.refresh(groupIds))
      }
    }
    .defaultSize(.init(width: 520, height: 500))
    .defaultPosition(.center)

    EditWorkflowGroupWindow(core.contentStore, configurationPublisher: core.configCoordinator.configurationPublisher) { context in
      core.sidebarCoordinator.handle(context)
      core.contentCoordinator.handle(context)
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)
    .defaultSize(.init(width: 520, height: 280))
  }

  private func handleScene(_ scene: AppScene) {
    guard KeyboardCowboy.env() != .previews else { return }
    switch scene {
    case .permissions:
      openWindow(id: KeyboardCowboy.permissionsWindowIdentifier)
      KeyboardCowboy.activate()
    case .mainWindow:
      if let mainWindow = KeyboardCowboy.mainWindow {
        mainWindow.makeKeyAndOrderFront(nil)
      } else {
        openWindow(id: KeyboardCowboy.mainWindowIdentifier)
      }
      KeyboardCowboy.activate()
    case .addGroup:
      openWindow(value: EditWorkflowGroupWindow.Context.add(WorkflowGroup.empty()))
    case .editGroup(let groupId):
      if let workflowGroup = core.groupStore.group(withId: groupId) {
        openWindow(value: EditWorkflowGroupWindow.Context.edit(workflowGroup))
      } else {
        assertionFailure("Unable to find workflow group")
      }
    }
  }
}
