import SwiftUI

@MainActor
struct MainWindowView: View {
  @Namespace var namespace
  private var focus: FocusState<AppFocus?>.Binding
  private let core: Core
  private let onSceneAction: (AppScene) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       core: Core,
       onSceneAction: @escaping (AppScene) -> Void) {
    self.focus = focus
    self.core = core
    self.onSceneAction = onSceneAction
  }

  var body: some View {
    ContainerView(
      focus,
      contentState: .readonly(core.contentStore.state),
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
        store.update(oldConfiguration)
        core.contentStore.use(oldConfiguration)
        core.sidebarCoordinator.handle(.refresh)
        core.contentCoordinator.handle(.refresh(core.groupSelectionManager.selections))
        core.detailCoordinator.handle(.selectWorkflow(workflowIds: core.contentSelectionManager.selections,
                                                      groupIds: core.groupSelectionManager.selections))
      })
    }
    .onAppear {
      KeyboardCowboy.activate()
    }
    .onDisappear {
      KeyboardCowboy.deactivate()
    }
  }
}
