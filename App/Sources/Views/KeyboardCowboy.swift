import Combine
import SwiftUI
import LaunchArguments

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

  private let contentStore: ContentStore
  private let groupStore: GroupStore
  private let scriptEngine: ScriptEngine
  private let engine: KeyboardCowboyEngine
  static let env: AppEnvironment = .development

  private var open: Bool = true

  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let scriptEngine = ScriptEngine(workspace: .shared)
    let indexer = Indexer()
    let contentStore = ContentStore(.designTime(),
                                    indexer: indexer,
                                    scriptEngine: scriptEngine,
                                    workspace: .shared)
    let contentCoordinator = ContentCoordinator(contentStore.groupStore,
                              applicationStore: contentStore.applicationStore)
    let engine = KeyboardCowboyEngine(contentStore, indexer: indexer,
                                      scriptEngine: scriptEngine, workspace: .shared)

    self.sidebarCoordinator = SidebarCoordinator(contentStore.groupStore,
                                                 contentPublisher: contentCoordinator.publisher,
                                                 applicationStore: contentStore.applicationStore)
    self.contentCoordinator = contentCoordinator
    self.configurationCoordinator = ConfigurationCoordinator(store: contentStore.configurationStore)
    self.detailCoordinator = DetailCoordinator(applicationStore: contentStore.applicationStore,
                                               contentStore: contentStore,
                                               keyboardCowboyEngine: engine,
                                               groupStore: contentStore.groupStore)

    self.contentStore = contentStore
    self.groupStore = contentStore.groupStore
    self.engine = engine
    self.scriptEngine = scriptEngine

    contentCoordinator.subscribe(to: sidebarCoordinator.groupIds.$model)
    detailCoordinator.subscribe(to: contentCoordinator.selectionPublisher.$model)
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
            }
          case .content(let contentAction):
            sidebarCoordinator.handle(contentAction)
          case .detail(let detailAction):
            Task {
              await detailCoordinator.handle(detailAction)
              contentCoordinator.handle(detailAction)
            }
          }
        }
      )
    }
    .windowStyle(.hiddenTitleBar)

    NewCommandWindow(contentStore: contentStore) { workflowId, commandId, title, payload in
      detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                           title: title, commandId: commandId)
    }

    EditWorkflowGroupWindow(contentStore)
      .windowResizability(.contentSize)
      .windowStyle(.hiddenTitleBar)
      .defaultPosition(.topTrailing)
      .defaultSize(.init(width: 520, height: 280))
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

private extension KeyboardCowboy {
  func applyEnvironmentObjects<Content: View>(_ content: @autoclosure () -> Content) -> some View {
    content()
      .environmentObject(contentStore.configurationStore)
      .environmentObject(contentStore.applicationStore)
      .environmentObject(contentStore.groupStore)
      .environmentObject(configurationCoordinator.publisher)
      .environmentObject(sidebarCoordinator.publisher)
      .environmentObject(sidebarCoordinator.groupIds)
      .environmentObject(contentCoordinator.publisher)
      .environmentObject(contentCoordinator.selectionPublisher)
      .environmentObject(detailCoordinator.statePublisher)
      .environmentObject(detailCoordinator.detailPublisher)
      .environmentObject(contentStore.recorderStore)
      .environmentObject(OpenPanelController())
  }
}
