import Foundation
import InputSources

@MainActor
final class Core {
  static private var appStorage: AppStorageStore = .init()

#if DEBUG
  static let config: AppPreferences = .designTime()
#else
  static let config: AppPreferences = .user()
#endif

  // MARK: - Coordinators

  lazy private(set) var configCoordinator = ConfigurationCoordinator(
    contentStore: contentStore,
    selectionManager: configSelectionManager,
    store: configurationStore)

  lazy private(set) var sidebarCoordinator = SidebarCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    configSelectionManager: configSelectionManager,
    groupSelectionManager: groupSelectionManager)

  lazy private(set) var contentCoordinator = ContentCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    contentSelectionManager: contentSelectionManager,
    groupSelectionManager: groupSelectionManager
  )

  lazy private(set) var detailCoordinator = DetailCoordinator(
    applicationStore: ApplicationStore.shared,
    applicationTriggerSelectionManager: applicationTriggerSelectionManager,
    commandRunner: commandRunner,
    commandSelectionManager: commandSelectionManager,
    contentSelectionManager: contentSelectionManager,
    contentStore: contentStore,
    groupSelectionManager: groupSelectionManager,
    keyboardCowboyEngine: engine,
    keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
    groupStore: contentStore.groupStore)

  // MARK: - Selection managers

  lazy private(set) var keyboardShortcutSelectionManager = SelectionManager<KeyShortcut>()
  lazy private(set) var applicationTriggerSelectionManager = SelectionManager<DetailViewModel.ApplicationTrigger>()
  lazy private(set) var commandSelectionManager = SelectionManager<CommandViewModel>()

  lazy private(set) var configSelectionManager = SelectionManager<ConfigurationViewModel>(initialSelection: [Self.appStorage.configId]) {
    Self.appStorage.configId = $0.first ?? ""
  }

  lazy private(set) var groupSelectionManager = SelectionManager<GroupViewModel>(initialSelection: Self.appStorage.groupIds) {
    Self.appStorage.groupIds = $0
  }

  lazy private(set) var contentSelectionManager = SelectionManager<ContentViewModel>(initialSelection: Self.appStorage.workflowIds) {
    Self.appStorage.workflowIds = $0
  }

  // MARK: - Stores

  lazy private(set) var configurationStore = ConfigurationStore()
  lazy private(set) var contentStore = ContentStore(
    Self.config,
    applicationStore: ApplicationStore.shared,
    configurationStore: configurationStore,
    groupStore: groupStore,
    keyboardShortcutsController: keyboardShortcutsController,
    recorderStore: recorderStore,
    shortcutStore: shortcutStore,
    scriptCommandRunner: scriptCommandRunner)
  lazy private(set) var groupStore = GroupStore()
  lazy private(set) var keyCodeStore = KeyCodesStore(InputSourceController())
  lazy private(set) var engine = KeyboardCowboyEngine(
    contentStore,
    commandRunner: commandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    keyboardShortcutsController: keyboardShortcutsController,
    keyCodeStore: keyCodeStore,
    scriptCommandRunner: scriptCommandRunner,
    shortcutStore: shortcutStore,
    workspace: .shared)
  lazy private(set) var recorderStore = KeyShortcutRecorderStore()
  lazy private(set) var shortcutStore = ShortcutStore(scriptCommandRunner)

  // MARK: - Runners
  lazy private(set) var commandRunner = CommandRunner(
    applicationStore: ApplicationStore.shared,
    scriptCommandRunner: scriptCommandRunner,
    keyboardCommandRunner: keyboardCommandRunner)
  lazy private(set) var keyboardCommandRunner = KeyboardCommandRunner(store: keyCodeStore)
  lazy private(set) var scriptCommandRunner = ScriptCommandRunner(workspace: .shared)

  // MARK: - Controllers

  lazy private(set) var keyboardShortcutsController = KeyboardShortcutsController()

  init() { }
}
