import Foundation
import InputSources
import SwiftUI

@MainActor
final class Core {
  // MARK: - Coordinators

  private(set) lazy var configCoordinator = ConfigurationCoordinator(
    contentStore: contentStore,
    configurationUpdater: configurationUpdater,
    selectionManager: configSelection,
    store: configurationStore,
  )

  private(set) lazy var sidebarCoordinator = SidebarCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    groupSelectionManager: groupSelection,
  )

  private(set) lazy var groupCoordinator = GroupCoordinator(
    groupStore,
    applicationStore: ApplicationStore.shared,
    groupSelectionManager: groupSelection,
    workflowsSelectionManager: workflowsSelection,
  )

  private(set) lazy var workflowCoordinator = WorkflowCoordinator(
    applicationStore: ApplicationStore.shared,
    applicationTriggerSelection: applicationTriggerSelection,
    commandRunner: commandRunner,
    commandSelection: commandSelection,
    workflowsSelection: workflowsSelection,
    contentStore: contentStore,
    groupSelection: groupSelection,
    keyboardCowboyEngine: engine,
    keyboardShortcutSelection: keyboardShortcutSelection,
    groupStore: contentStore.groupStore,
  )

  // MARK: - Selection managers

  private(set) lazy var keyboardShortcutSelection = SelectionManager<KeyShortcut>()
  private(set) lazy var applicationTriggerSelection = SelectionManager<DetailViewModel.ApplicationTrigger>()
  private(set) lazy var commandSelection = SelectionManager<CommandViewModel>()

  private(set) lazy var configSelection = SelectionManager<ConfigurationViewModel>(initialSelection: [AppStorageContainer.shared.configId]) {
    AppStorageContainer.shared.configId = $0.first ?? ""
  }

  private(set) lazy var groupSelection = SelectionManager<GroupViewModel>(initialSelection: AppStorageContainer.shared.groupIds) {
    AppStorageContainer.shared.groupIds = $0
  }

  private(set) lazy var workflowsSelection = SelectionManager<GroupDetailViewModel>(initialSelection: AppStorageContainer.shared.workflowIds) {
    AppStorageContainer.shared.workflowIds = $0
  }

  // MARK: - Stores

  private(set) lazy var configurationStore = ConfigurationStore()
  private(set) lazy var contentStore = ContentStore(
    AppPreferences.config,
    applicationStore: ApplicationStore.shared,
    configurationStore: configurationStore,
    groupStore: groupStore,
    shortcutResolver: shortcutResolver,
    recorderStore: recorderStore,
    shortcutStore: shortcutStore,
    scriptCommandRunner: scriptCommandRunner,
  )
  private(set) lazy var keyboardCleaner = KeyboardCleaner()
  private(set) lazy var macroCoordinator = MacroCoordinator(keyCodes: keyCodeStore)
  private(set) lazy var groupStore = GroupStore()
  private(set) lazy var keyCodeStore = KeyCodesStore(InputSourceController())
  private(set) lazy var notifications = MachPortUINotifications(shortcutResolver: shortcutResolver)
  private(set) lazy var tapHeldCoordinator = TapHeldCoordinator(defaultPartialMatch: .default())
  private(set) lazy var machPortCoordinator = MachPortCoordinator(
    store: keyboardCommandRunner.store,
    keyboardCleaner: keyboardCleaner,
    keyboardCommandRunner: keyboardCommandRunner,
    macroCoordinator: macroCoordinator,
    mode: .intercept,
    notifications: notifications,
    shortcutResolver: shortcutResolver,
    tapHeldCoordinator: tapHeldCoordinator,
    workflowRunner: workflowRunner,
  )

  private(set) lazy var engine = KeyboardCowboyEngine(
    contentStore,
    applicationActivityMonitor: applicationActivityMonitor,
    applicationTriggerController: applicationTriggerController,
    applicationWindowObserver: applicationWindowObserver,
    commandRunner: commandRunner,
    keyCodeStore: keyCodeStore,
    keyboardCommandRunner: keyboardCommandRunner,
    machPortCoordinator: machPortCoordinator,
    modifierTriggerController: modifierTriggerController,
    scriptCommandRunner: scriptCommandRunner,
    shortcutStore: shortcutStore,
    snippetController: snippetController,
    tapHeld: tapHeldCoordinator,
    uiElementCaptureStore: uiElementCaptureStore,
    workspace: .shared,
  )
  private(set) lazy var uiElementCaptureStore = UIElementCaptureStore()
  private(set) lazy var recorderStore = KeyShortcutRecorderStore()
  private(set) lazy var shortcutStore = ShortcutStore(scriptCommandRunner)
  private(set) lazy var commandLine = CommandLineCoordinator.shared
  private(set) lazy var applicationActivityMonitor = ApplicationActivityMonitor<UserSpace.Application>()
  private(set) lazy var applicationWindowObserver = ApplicationWindowObserver()

  // MARK: - Runners

  private(set) lazy var workflowRunner = WorkflowRunner(commandRunner: commandRunner,
                                                        store: keyCodeStore, notifications: notifications)
  private(set) lazy var repeatLastWorkflowRunner = RepeatLastWorkflowRunner()
  private(set) lazy var commandRunner = CommandRunner(
    applicationActivityMonitor: applicationActivityMonitor,
    applicationStore: ApplicationStore.shared,
    builtInCommandRunner: BuiltInCommandRunner(
      commandLine: commandLine,
      configurationStore: configurationStore,
      macroRunner: macroRunner,
      repeatLastWorkflowRunner: repeatLastWorkflowRunner,
      windowOpener: WindowOpener(core: self),
    ),
    scriptCommandRunner: scriptCommandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    systemCommandRunner: systemCommandRunner,
    uiElementCommandRunner: uiElementCommandRunner,
  )
  private(set) lazy var systemCommandRunner = SystemCommandRunner(applicationActivityMonitor: applicationActivityMonitor)
  private(set) lazy var keyboardCommandRunner = KeyboardCommandRunner(store: keyCodeStore)
  private(set) lazy var uiElementCommandRunner = UIElementCommandRunner()
  private(set) lazy var scriptCommandRunner = ScriptCommandRunner(workspace: .shared)
  private(set) lazy var macroRunner = MacroRunner(coordinator: macroCoordinator)
  private(set) lazy var snippetController = SnippetController(
    commandRunner: commandRunner,
    keyboardCommandRunner: keyboardCommandRunner,
    store: keyCodeStore,
  )

  private(set) lazy var applicationTriggerController = ApplicationTriggerController(workflowRunner)
  private(set) lazy var modifierTriggerController = ModifierTriggerController()

  private(set) lazy var inputSourceStore: InputSourceStore = .init()
  private(set) lazy var raycast = Raycast.Store()

  // MARK: - Controllers

  private(set) lazy var shortcutResolver = ShortcutResolver(keyCodes: keyCodeStore)

  private(set) lazy var configurationUpdater = ConfigurationUpdater(
    storageDebounce: .milliseconds(175),
    onRender: { [weak self] configuration, commit, _ in
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
    },
  )

  init() {}
}
