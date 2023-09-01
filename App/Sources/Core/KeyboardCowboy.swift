import ApplicationServices
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

private let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@main
struct KeyboardCowboy: App {
  static private var appStorage: AppStorageStore = .init()
  @Namespace var namespace
  @Environment(\.resetFocus) var resetFocus
  @FocusState var focus: AppFocus?
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private let sidebarCoordinator: SidebarCoordinator
  private let configurationCoordinator: ConfigurationCoordinator
  private let contentCoordinator: ContentCoordinator
  private let detailCoordinator: DetailCoordinator

  @ObservedObject private var contentStore: ContentStore
  private let groupStore: GroupStore
  private let scriptCommandRunner: ScriptCommandRunner
  private let engine: KeyboardCowboyEngine
#if DEBUG
  static let config: AppPreferences = .designTime()
  static let env: AppEnvironment = isRunningPreview ? .designTime : .development
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
    let scriptCommandRunner = ScriptCommandRunner(workspace: .shared)
    let keyboardShortcutsController = KeyboardShortcutsController()
    let applicationStore = ApplicationStore()
    let shortcutStore = ShortcutStore(scriptCommandRunner)
    let contentStore = ContentStore(Self.config,
                                    applicationStore: applicationStore,
                                    keyboardShortcutsController: keyboardShortcutsController,
                                    shortcutStore: shortcutStore,
                                    scriptCommandRunner: scriptCommandRunner)
    let keyCodeStore = KeyCodesStore(InputSourceController())
    let keyboardCommandRunner = KeyboardCommandRunner(store: keyCodeStore)
    let engine = KeyboardCowboyEngine(contentStore,
                                      keyboardCommandRunner: keyboardCommandRunner,
                                      keyboardShortcutsController: keyboardShortcutsController,
                                      keyCodeStore: keyCodeStore,
                                      scriptCommandRunner: scriptCommandRunner,
                                      shortcutStore: shortcutStore,
                                      workspace: .shared)

    // Selections
    let configSelectionManager = SelectionManager<ConfigurationViewModel>(initialSelection: [Self.appStorage.configId]) {
      Self.appStorage.configId = $0.first ?? ""
    }
    let groupSelectionManager = SelectionManager<GroupViewModel>(initialSelection: Self.appStorage.groupIds) {
      Self.appStorage.groupIds = $0
    }
    let contentSelectionManager = SelectionManager<ContentViewModel>(initialSelection: Self.appStorage.workflowIds) {
      Self.appStorage.workflowIds = $0
    }

    let keyboardShortcutSelectionManager = SelectionManager<KeyShortcut>()
    let applicationTriggerSelectionManager = SelectionManager<DetailViewModel.ApplicationTrigger>()
    let commandSelectionManager = SelectionManager<CommandViewModel>()

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
      groupSelectionManager: groupSelectionManager
    )

    let detailCoordinator = DetailCoordinator(applicationStore: applicationStore,
                                              applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                                              commandRunner: CommandRunner(applicationStore: applicationStore,
                                                                           scriptCommandRunner: scriptCommandRunner,
                                                                           keyboardCommandRunner: keyboardCommandRunner),
                                              commandSelectionManager: commandSelectionManager,
                                              contentSelectionManager: contentSelectionManager,
                                              contentStore: contentStore,
                                              groupSelectionManager: groupSelectionManager,
                                              keyboardCowboyEngine: engine,
                                              keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                                              groupStore: contentStore.groupStore)


    self.sidebarCoordinator = sidebarCoordinator
    self.configurationCoordinator = configCoordinator
    self.contentCoordinator = contentCoordinator
    self.detailCoordinator = detailCoordinator

    self.contentStore = contentStore
    self.groupStore = contentStore.groupStore
    self.engine = engine
    self.scriptCommandRunner = scriptCommandRunner

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

    WindowGroup(id: KeyboardCowboy.mainWindowIdentifier) {
      Group {
        switch contentStore.state {
        case .initialized:
          ContainerView(focus: $focus,
                        applicationTriggerSelectionManager: detailCoordinator.applicationTriggerSelectionManager,
                        commandSelectionManager: detailCoordinator.commandSelectionManager,
                        configSelectionManager: configurationCoordinator.selectionManager,
                        contentSelectionManager: contentCoordinator.contentSelectionManager,
                        groupsSelectionManager: sidebarCoordinator.selectionManager,
                        keyboardShortcutSelectionManager: detailCoordinator.keyboardShortcutSelectionManager
          ) { action, undoManager in

            let oldConfiguration = configurationCoordinator.store.selectedConfiguration

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
              contentCoordinator.handle(contentAction)
              detailCoordinator.handle(contentAction)
              if case .addWorkflow = contentAction {
                Task { @MainActor in focus = .detail(.name) }
              }
            case .detail(let detailAction):
              detailCoordinator.handle(detailAction)
              contentCoordinator.handle(detailAction)
            }

            undoManager?.registerUndo(withTarget: configurationCoordinator.store, handler: { store in
              store.update(oldConfiguration)
              contentStore.use(oldConfiguration)
              sidebarCoordinator.handle(.refresh)
              contentCoordinator.handle(.refresh(contentCoordinator.groupSelectionManager.selections))
              detailCoordinator.handle(.selectWorkflow(workflowIds: contentCoordinator.contentSelectionManager.selections,
                                                       groupIds: contentCoordinator.groupSelectionManager.selections))
            })
          }
          .focusScope(namespace)
          .environmentObject(contentStore.configurationStore)
          .environmentObject(contentStore.applicationStore)
          .environmentObject(contentStore.groupStore)
          .environmentObject(contentStore.shortcutStore)
          .environmentObject(configurationCoordinator.publisher)
          .environmentObject(sidebarCoordinator.publisher)
          .environmentObject(contentCoordinator.publisher)
          .environmentObject(detailCoordinator.statePublisher)
          .environmentObject(detailCoordinator.detailPublisher)
          .environmentObject(contentStore.recorderStore)
          .environmentObject(OpenPanelController())
          .matchedGeometryEffect(id: "content-window", in: namespace)
        case .loading:
          AppLoadingView(namespace: namespace)
            .frame(width: 560, height: 380)
            .matchedGeometryEffect(id: "content-window", in: namespace)
        case .noConfiguration:
          EmptyConfigurationView(namespace) {
            contentStore.handle($0)
          }
            .matchedGeometryEffect(id: "content-window", in: namespace)
            .frame(width: 560, height: 380)
            .animation(.none, value: contentStore.state)
        }
      }
      .animation(.easeInOut, value: contentStore.state)
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)

    PermissionsScene { action in
      switch action {
      case .github:
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy")!)
      case .requestPermissions:
        NSApplication.shared.keyWindow?.close()
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(privOptions)
      }
    }

    NewCommandWindow(contentStore: contentStore) { workflowId, commandId, title, payload in
      let groupIds = contentCoordinator.groupSelectionManager.selections
      Task {
        await detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                   title: title, commandId: commandId)
        contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId], groupIds: groupIds))
        contentCoordinator.handle(.refresh(groupIds))
      }
    }
    .defaultSize(.init(width: 520, height: 280))
    .defaultPosition(.center)

    EditWorkflowGroupWindow(contentStore) { context in
      sidebarCoordinator.handle(context)
      contentCoordinator.handle(context)
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
