import Combine
import Cocoa
import SwiftUI
import LaunchArguments
@_exported import Inject

@main
struct KeyboardCowboy: App {
  static private var appStorage: AppStorageStore = .init()
  @FocusState var containerFocus: ContainerView.Focus?
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private let sidebarCoordinator: SidebarCoordinator
  private let configurationCoordinator: ConfigurationCoordinator
  private let contentCoordinator: ContentCoordinator
  private let detailCoordinator: DetailCoordinator

  private let contentStore: ContentStore
  private let groupStore: GroupStore
  private let scriptEngine: ScriptEngine
  private let engine: KeyboardCowboyEngine
#if DEBUG
  static let config: AppPreferences = .designTime()
  static let env: AppEnvironment = .development
#else
  static let config: AppPreferences = .user()
  static let env: AppEnvironment = .production
#endif
  private var open: Bool = true


  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase

  init() {
    Inject.animation = .spring()

    // Core functionality
    let scriptEngine = ScriptEngine(workspace: .shared)
    let keyboardShortcutsCache = KeyboardShortcutsCache()
    let applicationStore = ApplicationStore()
    let shortcutStore = ShortcutStore(engine: scriptEngine)
    let contentStore = ContentStore(Self.config,
                                    applicationStore: applicationStore,
                                    keyboardShortcutsCache: keyboardShortcutsCache,
                                    shortcutStore: shortcutStore,
                                    scriptEngine: scriptEngine, workspace: .shared)
    let keyCodeStore = KeyCodesStore()
    let keyboardEngine = KeyboardEngine(store: keyCodeStore)
    let engine = KeyboardCowboyEngine(contentStore,
                                      keyboardEngine: keyboardEngine,
                                      keyboardShortcutsCache: keyboardShortcutsCache,
                                      scriptEngine: scriptEngine,
                                      shortcutStore: shortcutStore,
                                      workspace: .shared)

    // Selections
    let configSelectionManager = SelectionManager<ConfigurationViewModel>()
    let groupSelectionManager = SelectionManager<GroupViewModel>(initialSelection: Self.appStorage.groupIds) {
      Self.appStorage.groupIds = $0
    }
    let contentSelectionManager = SelectionManager<ContentViewModel>(initialSelection: Self.appStorage.workflowIds) {
      Self.appStorage.workflowIds = $0
    }

    // Coordinators
    let configCoordinator = ConfigurationCoordinator(
      contentStore: contentStore,
      selectionManager: configSelectionManager,
      store: contentStore.configurationStore)

    let sidebarCoordinator = SidebarCoordinator(
      contentStore.groupStore,
      applicationStore: applicationStore,
      configSelectionManager: configSelectionManager,
      groupSelectionManager: groupSelectionManager)

    let contentCoordinator = ContentCoordinator(
      contentStore.groupStore,
      applicationStore: applicationStore,
      contentSelectionManager: contentSelectionManager,
      groupSelectionManager: groupSelectionManager)

    let detailCoordinator = DetailCoordinator(applicationStore: applicationStore,
                                              commandEngine: CommandEngine(NSWorkspace.shared,
                                                                           scriptEngine: scriptEngine,
                                                                           keyboardEngine: keyboardEngine),
                                              contentSelectionManager: contentSelectionManager,
                                              contentStore: contentStore,
                                              groupSelectionManager: groupSelectionManager,
                                              keyboardCowboyEngine: engine,
                                              groupStore: contentStore.groupStore)


    self.sidebarCoordinator = sidebarCoordinator
    self.configurationCoordinator = configCoordinator
    self.contentCoordinator = contentCoordinator
    self.detailCoordinator = detailCoordinator

    self.contentStore = contentStore
    self.groupStore = contentStore.groupStore
    self.engine = engine
    self.scriptEngine = scriptEngine

    Benchmark.isEnabled = launchArguments.isEnabled(.benchmark)

    if launchArguments.isEnabled(.injection) { _ = Inject.load }
  }

  var body: some Scene {
    AppMenuBar { action in
      switch action {
      case .openMainWindow:
        handleScene(.mainWindow)
      case .reveal:
        NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
      }
    }

    WindowGroup(id: KeyboardCowboy.mainWindowIdentifier) {
      applyEnvironmentObjects(
        ContainerView(focus: $containerFocus,
                      configSelectionManager: configurationCoordinator.selectionManager,
                      contentSelectionManager: contentCoordinator.selectionManager,
                      groupsSelectionManager: sidebarCoordinator.selectionManager
                     ) { action in
          switch action {
          case .openScene(let scene):
            handleScene(scene)
          case .sidebar(let sidebarAction):
            switch sidebarAction {
            case .openScene(let scene):
              handleScene(scene)
            default:
              configurationCoordinator.handle(sidebarAction)
              sidebarCoordinator.handle(sidebarAction)
              contentCoordinator.handle(sidebarAction)
              detailCoordinator.handle(sidebarAction)
            }
          case .content(let contentAction):
            Task {
              await contentCoordinator.handle(contentAction)
              detailCoordinator.handle(contentAction)
              if case .addWorkflow = contentAction {
                containerFocus = .content
              }
            }
          case .detail(let detailAction):
            detailCoordinator.handle(detailAction)
            contentCoordinator.handle(detailAction)
          }
        }
        // MARK: Note - Force dark mode until the light theme is up-to-date
        .environment(\.colorScheme, .dark)
      )
    }
    .windowStyle(.hiddenTitleBar)

    NewCommandWindow(contentStore: contentStore) { workflowId, commandId, title, payload in
      let groupIds = contentCoordinator.groupSelectionManager.selections
      Task {
        await detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                   title: title, commandId: commandId)
        await contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId], groupIds: groupIds))
        await contentCoordinator.handle(.rerender(groupIds))
      }
    }
    .defaultSize(.init(width: 520, height: 280))
    .defaultPosition(.center)

    EditWorkflowGroupWindow(contentStore) { context in
      sidebarCoordinator.handle(context)
    }
      .windowResizability(.contentSize)
      .windowStyle(.hiddenTitleBar)
      .defaultPosition(.center)
      .defaultSize(.init(width: 520, height: 280))
  }

  private func handleScene(_ scene: AppScene) {
    guard !isRunningPreview else { return }
    switch scene {
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
      if let workflowGroup = groupStore.group(withId: groupId) {
        openWindow(value: EditWorkflowGroupWindow.Context.edit(workflowGroup))
      } else {
        assertionFailure("Unable to find workflow group")
      }
    }
  }
}

private extension KeyboardCowboy {
  func applyEnvironmentObjects<Content: View>(_ content: @autoclosure () -> Content) -> some View {
    content()
      .environmentObject(contentStore.configurationStore)
      .environmentObject(contentStore.applicationStore)
      .environmentObject(contentStore.groupStore)
      .environmentObject(configurationCoordinator.publisher)
      .environmentObject(sidebarCoordinator.publisher)
      .environmentObject(contentCoordinator.publisher)
      .environmentObject(detailCoordinator.statePublisher)
      .environmentObject(detailCoordinator.detailPublisher)
      .environmentObject(contentStore.recorderStore)
      .environmentObject(OpenPanelController())
  }
}
