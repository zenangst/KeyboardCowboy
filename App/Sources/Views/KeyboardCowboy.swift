import Combine
import SwiftUI
import LaunchArguments
@_exported import Inject

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
let launchArguments = LaunchArgumentsController<LaunchArgument>()

@main
struct KeyboardCowboy: App {
  @FocusState private var focus: Focus?
  @ObservedObject private var contentStore: ContentStore
  @ObservedObject private var groupStore: GroupStore
  private let scriptEngine: ScriptEngine
  private let engine: KeyboardCowboyEngine

  private var workflowSubscription: AnyCancellable?

  init() {
    let scriptEngine = ScriptEngine(workspace: .shared)
    let contentStore = ContentStore(.user(), scriptEngine: scriptEngine, workspace: .shared)
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
    WindowGroup {
      ContentView(
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
      .equatable()
    }
  }
}
