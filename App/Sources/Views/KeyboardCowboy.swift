import Combine
import SwiftUI
import LaunchArguments
@_exported import Inject

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
let launchArguments = LaunchArgumentsController<LaunchArgument>()

enum AppEnvironment: String, Hashable, Identifiable {
  var id: String { rawValue }

  case development
  case production
}

enum AppScene {
  case mainWindow
  case addGroup
  case editGroup(GroupViewModel.ID)
}

@main
struct KeyboardCowboy: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  /// New
  private let sidebarCoordinator: SidebarCoordinator
  private let configurationCoordinator: ConfigurationCoordinator
  private let contentCoordinator: ContentCoordinator
  private let detailCoordinator: DetailCoordinator

  /// Old
  @FocusState private var focus: Focus?
  @ObservedObject private var contentStore: ContentStore
  @ObservedObject private var groupStore: GroupStore
  private let scriptEngine: ScriptEngine
  private let engine: KeyboardCowboyEngine
  static let env: AppEnvironment = .development

  private var workflowSubscription: AnyCancellable?
  private var open: Bool = true

  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let scriptEngine = ScriptEngine(workspace: .shared)
    let contentStore = ContentStore(.designTime(), scriptEngine: scriptEngine, workspace: .shared)
    let contentCoordinator = ContentCoordinator(contentStore.groupStore,
                              applicationStore: contentStore.applicationStore)

    self.sidebarCoordinator = SidebarCoordinator(contentStore.groupStore,
                                                 contentPublisher: contentCoordinator.publisher,
                                                 applicationStore: contentStore.applicationStore)
    self.contentCoordinator = contentCoordinator
    self.configurationCoordinator = ConfigurationCoordinator(store: contentStore.configurationStore)
    self.detailCoordinator = DetailCoordinator(applicationStore: contentStore.applicationStore,
                                               contentStore: contentStore,
                                               groupStore: contentStore.groupStore)

    _contentStore = .init(initialValue: contentStore)
    _groupStore = .init(initialValue: contentStore.groupStore)
    self.engine = KeyboardCowboyEngine(contentStore, scriptEngine: scriptEngine, workspace: .shared)
    self.scriptEngine = scriptEngine
    self.focus = .main(.groupComponent)

    Inject.animation = .easeInOut(duration: 0.175)

    guard KeyboardCowboy.env == .production else { return }

    workflowSubscription = contentStore.$selectedWorkflows
      .dropFirst(2)
      .removeDuplicates()
      .filter({ $0 != contentStore.selectedWorkflowsCopy })
      .sink(receiveValue: { workflows in
        contentStore.updateWorkflows(workflows)
      })
  }

  var body: some Scene {
    AppMenuBar { action in
      switch action {
      case .openMainWindow:
        handleScene(.mainWindow)
      }
    }

    WindowGroup(id: KeyboardCowboy.mainWindowIdentifier) {
      switch KeyboardCowboy.env {
      case .development:
        ContainerView { action in
          switch action {
          case .openScene(let scene):
            handleScene(scene)
          case .sidebar(let sidebarAction):
            switch sidebarAction {
            case .openScene(let scene):
              handleScene(scene)
            default:
              sidebarCoordinator.handle(sidebarAction)
              contentCoordinator.handle(sidebarAction)
            }
          case .content(let contentAction):
            sidebarCoordinator.handle(contentAction)
            detailCoordinator.handle(contentAction)
          case .detail(let detailAction):
            detailCoordinator.handle(detailAction)
            contentCoordinator.handle(detailAction)
          }
        }
        .environmentObject(contentStore.configurationStore)
        .environmentObject(contentStore.applicationStore)
        .environmentObject(contentStore.groupStore)

        .environmentObject(configurationCoordinator.publisher)
        .environmentObject(sidebarCoordinator.publisher)
        .environmentObject(contentCoordinator.publisher)
        .environmentObject(detailCoordinator.publisher)
      case .production:
        LegacyContentView(
          contentStore,
          selectedGroups: $groupStore.selectedGroups,
          selectedWorkflows: $contentStore.selectedWorkflows,
          focus: _focus) { action in
            switch action {
            case .run(let command):
              engine.run([command], serial: true)
            case .reveal(let command):
              engine.reveal([command])
            }
          }
      }
    }

    EditWorkflowGroupWindow(contentStore)
      .windowResizability(.contentSize)
      .defaultPosition(.topTrailing)
      .defaultSize(.init(width: 520, height: 280))
      .windowStyle(.hiddenTitleBar)
  }

  private func handleScene(_ scene: AppScene) {
    switch scene {
    case .mainWindow:
      openWindow(id: KeyboardCowboy.mainWindowIdentifier)
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
      switch KeyboardCowboy.env {
      case .development:
        guard !isRunningPreview else { return }
        KeyboardCowboy.activate()
      case .production:
        KeyboardCowboy.mainWindow?.close()
      }
    }
}
