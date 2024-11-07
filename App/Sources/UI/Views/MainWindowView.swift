import SwiftUI

@MainActor
struct MainWindowView: View {
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
      contentState: .readonly(core.contentStore.state),
      detailUpdateTransaction: core.detailCoordinator.updateTransaction,
      publisher: core.contentCoordinator.contentPublisher,
      applicationTriggerSelectionManager: core.applicationTriggerSelectionManager,
      commandSelectionManager: core.commandSelectionManager,
      configSelectionManager: core.configSelectionManager,
      contentSelectionManager: core.contentSelectionManager,
      groupsSelectionManager: core.groupSelectionManager,
      keyboardShortcutSelectionManager: core.keyboardShortcutSelectionManager,
      triggerPublisher: core.detailCoordinator.triggerPublisher,
      infoPublisher: core.detailCoordinator.infoPublisher,
      commandPublisher: core.detailCoordinator.commandsPublisher
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
          core.contentCoordinator.handle(sidebarAction)
          core.detailCoordinator.handle(sidebarAction)
        }
      case .content(let contentAction):
        core.contentCoordinator.handle(contentAction)
        core.detailCoordinator.handle(contentAction)
      case .detail(let detailAction):
        core.detailCoordinator.handle(detailAction)
        core.contentCoordinator.handle(detailAction)
      }

      undoManager?.registerUndo(withTarget: core.configurationStore, handler: { store in
        Task { @MainActor in
          store.update(oldConfiguration)
          core.contentStore.use(oldConfiguration)
          core.sidebarCoordinator.handle(.refresh)
          core.contentCoordinator.handle(.refresh(core.groupSelectionManager.selections))
          core.detailCoordinator.handle(.selectWorkflow(workflowIds: core.contentSelectionManager.selections))
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
    .environmentObject(core.contentCoordinator.contentPublisher)
    .environmentObject(core.contentCoordinator.groupPublisher)
    .environmentObject(core.detailCoordinator.statePublisher)
    .environmentObject(core.detailCoordinator.infoPublisher)
    .environmentObject(core.detailCoordinator.triggerPublisher)
    .environmentObject(core.detailCoordinator.commandsPublisher)
    .environmentObject(core.snippetController)
    .environmentObject(OpenPanelController())
  }
}
