import Foundation
import InputSources

@MainActor
final class Core {
  static var config: AppPreferences {
    switch KeyboardCowboy.env() {
    case .development: .designTime()
    case .previews: .designTime()
    case .production: .user()
    }
  }

  // MARK: - Coordinators

  lazy private(set) var configCoordinator = ConfigurationCoordinator(
    contentStore: contentStore,
    selectionManager: configSelectionManager,
    store: configurationStore)

  lazy private(set) var sidebarCoordinator = SidebarCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
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

  lazy private(set) var configSelectionManager = SelectionManager<ConfigurationViewModel>(initialSelection: [AppStorageContainer.shared.configId]) {
    AppStorageContainer.shared.configId = $0.first ?? ""
  }

  lazy private(set) var groupSelectionManager = SelectionManager<GroupViewModel>(initialSelection: AppStorageContainer.shared.groupIds) {
    AppStorageContainer.shared.groupIds = $0
  }

  lazy private(set) var contentSelectionManager = SelectionManager<ContentViewModel>(initialSelection: AppStorageContainer.shared.workflowIds) {
    AppStorageContainer.shared.workflowIds = $0
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
  lazy private(set) var macroCoordinator = MacroCoordinator()
  lazy private(set) var groupStore = GroupStore()
  lazy private(set) var keyCodeStore = KeyCodesStore(InputSourceController())
  lazy private(set) var workflowRunner = WorkflowRunner(commandRunner: commandRunner,
                                                        store: keyCodeStore, notifications: notifications)
  lazy private(set) var notifications = MachPortUINotifications(keyboardShortcutsController: keyboardShortcutsController)
  lazy private(set) var machPortCoordinator = MachPortCoordinator(store: keyboardCommandRunner.store,
                                                                  commandRunner: commandRunner,
                                                                  keyboardCommandRunner: keyboardCommandRunner,
                                                                  keyboardShortcutsController: keyboardShortcutsController,
                                                                  macroCoordinator: macroCoordinator,
                                                                  mode: .intercept,
                                                                  notifications: notifications,
                                                                  workflowRunner: workflowRunner)
  lazy private(set) var engine = KeyboardCowboyEngine(
    contentStore,
    commandRunner: commandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    keyboardShortcutsController: keyboardShortcutsController,
    keyCodeStore: keyCodeStore,
    machPortCoordinator: machPortCoordinator,
    scriptCommandRunner: scriptCommandRunner,
    shortcutStore: shortcutStore,
    uiElementCaptureStore: uiElementCaptureStore,
    workspace: .shared)
  lazy private(set) var uiElementCaptureStore = UIElementCaptureStore()
  lazy private(set) var recorderStore = KeyShortcutRecorderStore()
  lazy private(set) var shortcutStore = ShortcutStore(scriptCommandRunner)

  // MARK: - Runners
  lazy private(set) var commandRunner = CommandRunner(
    applicationStore: ApplicationStore.shared,
    builtInCommandRunner: BuiltInCommandRunner(configurationStore: configurationStore),
    scriptCommandRunner: scriptCommandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    uiElementCommandRunner: uiElementCommandRunner
  )
  lazy private(set) var keyboardCommandRunner = KeyboardCommandRunner(store: keyCodeStore)
  lazy private(set) var uiElementCommandRunner = UIElementCommandRunner()
  lazy private(set) var scriptCommandRunner = ScriptCommandRunner(workspace: .shared)

  // MARK: - Controllers

  lazy private(set) var keyboardShortcutsController = KeyboardShortcutsController()

  init() { }
}
