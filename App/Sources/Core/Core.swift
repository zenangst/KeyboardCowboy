import Foundation
import InputSources
import SwiftUI

@MainActor
final class Core {

  // MARK: - Coordinators

  lazy private(set) var configCoordinator = ConfigurationCoordinator(
    contentStore: contentStore,
    configurationUpdater: configurationUpdater,
    selectionManager: configSelection,
    store: configurationStore)

  lazy private(set) var sidebarCoordinator = SidebarCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    groupSelectionManager: groupSelection)

  lazy private(set) var groupCoordinator = GroupCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    groupSelectionManager: groupSelection,
    workflowsSelectionManager: workflowsSelection
  )

  lazy private(set) var workflowCoordinator = WorkflowCoordinator(
    applicationStore: ApplicationStore.shared,
    applicationTriggerSelection: applicationTriggerSelection,
    commandRunner: commandRunner,
    commandSelection: commandSelection,
    workflowsSelection: workflowsSelection,
    contentStore: contentStore,
    groupSelection: groupSelection,
    keyboardCowboyEngine: engine,
    keyboardShortcutSelection: keyboardShortcutSelection,
    groupStore: contentStore.groupStore)

  // MARK: - Selection managers

  lazy private(set) var keyboardShortcutSelection = SelectionManager<KeyShortcut>()
  lazy private(set) var applicationTriggerSelection = SelectionManager<DetailViewModel.ApplicationTrigger>()
  lazy private(set) var commandSelection = SelectionManager<CommandViewModel>()

  lazy private(set) var configSelection = SelectionManager<ConfigurationViewModel>(initialSelection: [AppStorageContainer.shared.configId]) {
    AppStorageContainer.shared.configId = $0.first ?? ""
  }

  lazy private(set) var groupSelection = SelectionManager<GroupViewModel>(initialSelection: AppStorageContainer.shared.groupIds) {
    AppStorageContainer.shared.groupIds = $0
  }

  lazy private(set) var workflowsSelection = SelectionManager<GroupDetailViewModel>(initialSelection: AppStorageContainer.shared.workflowIds) {
    AppStorageContainer.shared.workflowIds = $0
  }

  // MARK: - Stores

  lazy private(set) var configurationStore = ConfigurationStore()
  lazy private(set) var contentStore = ContentStore(
    AppPreferences.config,
    applicationStore: ApplicationStore.shared,
    configurationStore: configurationStore,
    groupStore: groupStore,
    shortcutResolver: shortcutResolver,
    recorderStore: recorderStore,
    shortcutStore: shortcutStore,
    scriptCommandRunner: scriptCommandRunner)
  lazy private(set) var keyboardCleaner = KeyboardCleaner()
  lazy private(set) var macroCoordinator = MacroCoordinator(keyCodes: keyCodeStore)
  lazy private(set) var groupStore = GroupStore()
  lazy private(set) var keyCodeStore = KeyCodesStore(InputSourceController())
  lazy private(set) var notifications = MachPortUINotifications(shortcutResolver: shortcutResolver)
  lazy private(set) var leaderKeyCoordinator = LeaderKeyCoordinator(defaultPartialMatch: .default())
  lazy private(set) var machPortCoordinator = MachPortCoordinator(store: keyboardCommandRunner.store,
                                                                  leaderKeyCoordinator: leaderKeyCoordinator,
                                                                  keyboardCleaner: keyboardCleaner,
                                                                  keyboardCommandRunner: keyboardCommandRunner,
                                                                  shortcutResolver: shortcutResolver,
                                                                  macroCoordinator: macroCoordinator,
                                                                  mode: .intercept,
                                                                  notifications: notifications,
                                                                  workflowRunner: workflowRunner)
  lazy private(set) var engine = KeyboardCowboyEngine(
    contentStore,
    applicationActivityMonitor: applicationActivityMonitor,
    applicationTriggerController: applicationTriggerController,
//    applicationWindowObserver: applicationWindowObserver,
    commandRunner: commandRunner,
    leaderKey: leaderKeyCoordinator,
    keyboardCommandRunner: keyboardCommandRunner,
    keyCodeStore: keyCodeStore,
    machPortCoordinator: machPortCoordinator,
    modifierTriggerController: modifierTriggerController,
    scriptCommandRunner: scriptCommandRunner,
    shortcutStore: shortcutStore,
    snippetController: snippetController,
    spaces: spaces,
    uiElementCaptureStore: uiElementCaptureStore,
    workspace: .shared)
  lazy private(set) var uiElementCaptureStore = UIElementCaptureStore()
  lazy private(set) var recorderStore = KeyShortcutRecorderStore()
  lazy private(set) var shortcutStore = ShortcutStore.shared
  lazy private(set) var commandLine = CommandLineCoordinator.shared
  lazy private(set) var applicationActivityMonitor = ApplicationActivityMonitor<UserSpace.Application>()
//  lazy private(set) var applicationWindowObserver = ApplicationWindowObserver()

  // MARK: - Runners
  lazy private(set) var workflowRunner = WorkflowRunner(commandRunner: commandRunner,
                                                        store: keyCodeStore, notifications: notifications)
  lazy private(set) var repeatLastWorkflowRunner = RepeatLastWorkflowRunner()
  lazy private(set) var commandRunner = CommandRunner(
    applicationStore: ApplicationStore.shared,
    builtInCommandRunner: BuiltInCommandRunner(
      commandLine: commandLine,
      configurationStore: configurationStore,
      macroRunner: macroRunner,
      repeatLastWorkflowRunner: repeatLastWorkflowRunner,
      windowOpener: WindowOpener(core: self)
    ),
    scriptCommandRunner: scriptCommandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    systemCommandRunner: systemCommandRunner,
    uiElementCommandRunner: uiElementCommandRunner
  )
  lazy private(set) var systemCommandRunner = SystemCommandRunner(applicationActivityMonitor: applicationActivityMonitor)
  lazy private(set) var keyboardCommandRunner = KeyboardCommandRunner(store: keyCodeStore)
  lazy private(set) var uiElementCommandRunner = UIElementCommandRunner()
  lazy private(set) var scriptCommandRunner = ScriptCommandRunner(workspace: .shared)
  lazy private(set) var macroRunner = MacroRunner(coordinator: macroCoordinator)
  lazy private(set) var snippetController = SnippetController(
    commandRunner: commandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    store: keyCodeStore
  )

  lazy private(set) var applicationTriggerController = ApplicationTriggerController(workflowRunner)
  lazy private(set) var modifierTriggerController = ModifierTriggerController()

  lazy private(set) var inputSourceStore: InputSourceStore = .init()
  lazy private(set) var raycast = Raycast.Store()

  // MARK: - Controllers

  lazy private(set) var shortcutResolver = ShortcutResolver(keyCodes: keyCodeStore)

  lazy private(set) var configurationUpdater = ConfigurationUpdater(
    storageDebounce: .milliseconds(175),
    onRender: { [weak self] configuration, commit, animation in
      guard let self else { return }
      groupStore.updateGroups(Set(configuration.groups))
      sidebarCoordinator.handle(.selectGroups([commit.groupID]))
      groupCoordinator.handle(.selectGroups([commit.groupID]))
      workflowCoordinator.handle(.selectGroups([commit.groupID]))
    },
    onStorageUpdate: { [weak self] configuration, commit in
      guard let self else { return }
      withAnimation { [groupCoordinator] in
        groupCoordinator.handle(.refresh([commit.groupID]))
      }
      configurationStore.update(configuration)
  })

  lazy private(set) var spaces: SpacesCoordinator = SpacesCoordinator(store: keyCodeStore)

  init() { }
}
