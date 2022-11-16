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

@main
struct KeyboardCowboy: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  enum ApplicationState {
    case active, inactive

    var iconName: String {
      switch self {
      case .active: return "Menubar_active"
      case .inactive: return "Menubar_inactive"
      }
    }
  }

  /// New
  private let sidebarCoordinator: SidebarCoordinator
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

  init() {
    let scriptEngine = ScriptEngine(workspace: .shared)
    let contentStore = ContentStore(.user(), scriptEngine: scriptEngine, workspace: .shared)

    sidebarCoordinator = SidebarCoordinator(contentStore.groupStore,
                                            applicationStore: contentStore.applicationStore)
    contentCoordinator = ContentCoordinator(contentStore.groupStore)
    detailCoordinator = DetailCoordinator(contentStore.groupStore)

    _contentStore = .init(initialValue: contentStore)
    _groupStore = .init(initialValue: contentStore.groupStore)
    self.engine = KeyboardCowboyEngine(contentStore, scriptEngine: scriptEngine, workspace: .shared)
    self.scriptEngine = scriptEngine
    self.focus = .main(.groupComponent)

    Inject.animation = .easeInOut(duration: 0.175)

    workflowSubscription = contentStore.$selectedWorkflows
      .dropFirst(2)
      .removeDuplicates()
      .filter({ $0 != contentStore.selectedWorkflowsCopy })
      .sink(receiveValue: { workflows in
        contentStore.updateWorkflows(workflows)
      })
  }

  var body: some Scene {
    WindowGroup(id: "MainWindow") {
      switch Self.env {
      case .development:
        ContainerView { action in
          switch action {
          case .sidebar(let sidebarAction):
            sidebarCoordinator.handle(sidebarAction)
            contentCoordinator.handle(sidebarAction)
          case .content(let contentAction):
            detailCoordinator.handle(contentAction)
          case .detail(let detailAction):
            detailCoordinator.handle(detailAction)
          }
        }
          .environmentObject(DesignTime.configurationPublisher)
          .environmentObject(contentStore.applicationStore)
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


    MenuBarExtra(content: {
      Button("Open Keyboard Cowboy", action: {
        openWindow(id: "MainWindow")
      })
      Divider()
      Button("Check for updates...", action: {})
      Button("Provide feedback...", action: {
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/new")!)
      })
      Divider()
      Button("Quit") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q", modifiers: [.command])
    }) {
      Image(ApplicationState.inactive.iconName)
        .resizable()
        .renderingMode(.template)
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
      NSApplication.shared.windows
        .filter { $0.identifier?.rawValue.contains("MainWindow") == true }
        .forEach { window in
          window.close()
        }
    }
}
