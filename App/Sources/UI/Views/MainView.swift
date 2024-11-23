import SwiftUI

@MainActor
struct MainView: View {
  @FocusState var focus: AppFocus?
  @Namespace var namespace
  private let core: Core
  private let onSceneAction: (AppScene) -> Void

  init(core: Core, onSceneAction: @escaping (AppScene) -> Void) {
    self.core = core
    self.onSceneAction = onSceneAction
  }

  var body: some View {
    ContainerView(
      $focus,
      contentState: .readonly { core.contentStore.state },
      detailUpdateTransaction: core.workflowCoordinator.updateTransaction,
      publisher: core.groupCoordinator.contentPublisher,
      applicationTriggerSelection: core.applicationTriggerSelection,
      commandSelection: core.commandSelection,
      configSelection: core.configSelection,
      contentSelection: core.workflowsSelection,
      groupsSelection: core.groupSelection,
      keyboardShortcutSelection: core.keyboardShortcutSelection,
      triggerPublisher: core.workflowCoordinator.triggerPublisher,
      infoPublisher: core.workflowCoordinator.infoPublisher,
      commandPublisher: core.workflowCoordinator.commandsPublisher
    ) { action, undoManager in
      let oldConfiguration = core.configurationStore.selectedConfiguration

      switch action {
      case .openScene(let scene):
        onSceneAction(scene)
      case .sidebar(let sidebarAction):
        switch sidebarAction {
        case .openScene(let scene):
          onSceneAction(scene)
        default:
          core.configCoordinator.handle(sidebarAction)
          core.sidebarCoordinator.handle(sidebarAction)
          core.groupCoordinator.handle(sidebarAction)
          core.workflowCoordinator.handle(sidebarAction)
        }
      case .content(let contentAction):
        core.groupCoordinator.handle(contentAction)
        core.workflowCoordinator.handle(contentAction)
      }

      undoManager?.registerUndo(withTarget: core.configurationStore, handler: { store in
        Task { @MainActor in
          store.update(oldConfiguration)
          core.contentStore.use(oldConfiguration)
          core.sidebarCoordinator.handle(.refresh)
          core.groupCoordinator.handle(.refresh(core.groupSelection.selections))
          core.workflowCoordinator.handle(.selectWorkflow(workflowIds: core.workflowsSelection.selections))
        }
      })
    }
    .environmentObject(ApplicationStore.shared)
    .environmentObject(core.contentStore)
    .environmentObject(core.groupStore)
    .environmentObject(core.shortcutStore)
    .environmentObject(core.recorderStore)
    .environmentObject(core.configCoordinator.configurationsPublisher)
    .environmentObject(core.configCoordinator.configurationPublisher)
    .environmentObject(core.sidebarCoordinator.publisher)
    .environmentObject(core.groupCoordinator.contentPublisher)
    .environmentObject(core.groupCoordinator.groupPublisher)
    .environmentObject(core.workflowCoordinator.statePublisher)
    .environmentObject(core.workflowCoordinator.infoPublisher)
    .environmentObject(core.workflowCoordinator.triggerPublisher)
    .environmentObject(core.workflowCoordinator.commandsPublisher)
    .environmentObject(core.snippetController)
    .environmentObject(OpenPanelController())
  }
}
