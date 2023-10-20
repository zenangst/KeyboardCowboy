import ApplicationServices
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

@main
struct KeyboardCowboy: App {
#if DEBUG
  static let env: AppEnvironment = .development
#else
  static let env: AppEnvironment = .production
#endif

  static private var appStorage: AppStorageStore = .init()
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

    Inject.animation = .spring()
    Benchmark.isEnabled = launchArguments.isEnabled(.benchmark)
    if launchArguments.isEnabled(.injection) { _ = Inject.load }
  }

  var body: some Scene {
    AppMenuBar(onAction:  { action in
      guard !launchArguments.isEnabled(.runningUnitTests) else { return }
      switch action {
      case .onAppear:
        if KeyboardCowboy.env == .development {
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
      VStack {
        switch core.contentStore.state {
        case .initialized:
          ContainerView(applicationTriggerSelectionManager: core.applicationTriggerSelectionManager,
                        commandSelectionManager: core.commandSelectionManager,
                        configSelectionManager: core.configSelectionManager,
                        contentSelectionManager: core.contentSelectionManager,
                        groupsSelectionManager: core.groupSelectionManager,
                        keyboardShortcutSelectionManager: core.keyboardShortcutSelectionManager
          ) { action, undoManager in

            let oldConfiguration = core.configurationStore.selectedConfiguration

            switch action {
            case .openScene(let scene):
              handleScene(scene)
            case .sidebar(let sidebarAction):
              switch sidebarAction {
              case .openScene(let scene):
                handleScene(scene)
              default:
                core.configCoordinator.handle(sidebarAction)
                core.sidebarCoordinator.handle(sidebarAction)
                core.contentCoordinator.handle(sidebarAction)
                core.detailCoordinator.handle(sidebarAction)
              }
            case .content(let contentAction):
              core.contentCoordinator.handle(contentAction)
              core.detailCoordinator.handle(contentAction)
            case .detail(let detailAction):
              core.detailCoordinator.handle(detailAction)
              core.contentCoordinator.handle(detailAction)
            }

            undoManager?.registerUndo(withTarget: core.configurationStore, handler: { store in
              store.update(oldConfiguration)
              core.contentStore.use(oldConfiguration)
              core.sidebarCoordinator.handle(.refresh)
              core.contentCoordinator.handle(.refresh(core.groupSelectionManager.selections))
              core.detailCoordinator.handle(.selectWorkflow(workflowIds: core.contentSelectionManager.selections,
                                                            groupIds: core.groupSelectionManager.selections))
            })
          }
          .focusScope(namespace)

          .environmentObject(ApplicationStore.shared)
          .environmentObject(core.contentStore)
          .environmentObject(core.groupStore)
          .environmentObject(core.shortcutStore)
          .environmentObject(core.recorderStore)

          .environmentObject(core.configCoordinator.publisher)
          .environmentObject(core.sidebarCoordinator.publisher)
          .environmentObject(core.contentCoordinator.contentPublisher)
          .environmentObject(core.contentCoordinator.groupPublisher)
          .environmentObject(core.detailCoordinator.statePublisher)
          .environmentObject(core.detailCoordinator.infoPublisher)
          .environmentObject(core.detailCoordinator.triggerPublisher)
          .environmentObject(core.detailCoordinator.commandsPublisher)

          .environmentObject(OpenPanelController())
          .matchedGeometryEffect(id: "content-window", in: namespace)
        case .loading:
          AppLoadingView(namespace: namespace)
            .frame(width: 560, height: 380)
            .matchedGeometryEffect(id: "content-window", in: namespace)
        case .noConfiguration:
          EmptyConfigurationView(namespace) {
            core.contentStore.handle($0)
          }
            .matchedGeometryEffect(id: "content-window", in: namespace)
            .frame(width: 560, height: 380)
            .animation(.none, value: core.contentStore.state)
        }
      }
      .animation(.easeInOut, value: core.contentStore.state)
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)

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

    NewCommandWindow(contentStore: core.contentStore) { workflowId, commandId, title, payload in
      let groupIds = core.groupSelectionManager.selections
      Task {
        await core.detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                               title: title, commandId: commandId)
        core.contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId], groupIds: groupIds))
        core.contentCoordinator.handle(.refresh(groupIds))
      }
    }
    .defaultSize(.init(width: 520, height: 280))
    .defaultPosition(.center)

    EditWorkflowGroupWindow(core.contentStore) { context in
      core.sidebarCoordinator.handle(context)
      core.contentCoordinator.handle(context)
    }
      .windowResizability(.contentSize)
      .windowStyle(.hiddenTitleBar)
      .defaultPosition(.center)
      .defaultSize(.init(width: 520, height: 280))
  }

  private func handleScene(_ scene: AppScene) {
    guard KeyboardCowboy.env != .designTime else { return }
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
