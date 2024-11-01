import AppKit
import SwiftUI

@MainActor
final class WindowOpener: ObservableObject {
  private let core: Core
  private var groupWindow: GroupWindow?
  private var newCommandWindow: NewCommandWindow?
  private var mainWindow: MainWindow?
  private var permissions: Permissions?
  private var releaseNotes: ReleaseNotes?
  private var emptyConfig: EmptyConfiguration?

  init(core: Core) {
    self.core = core
  }

  func openMainWindow() {
    let mainWindow = MainWindow(core: core)
    mainWindow.open()
    self.mainWindow = mainWindow
  }

  func openGroup(_ context: GroupWindow.Context) {
    let groupWindow = GroupWindow(
      context: context,
      applicationStore: ApplicationStore.shared,
      configurationPublisher: core.configCoordinator.configurationPublisher,
      contentPublisher: core.contentCoordinator.contentPublisher,
      contentCoordinator: core.contentCoordinator,
      sidebarCoordinator: core.sidebarCoordinator
    )
    groupWindow.open(context)
    self.groupWindow = groupWindow
  }

  func openPermissions() {
    let permissions = Permissions()
    permissions.open()
    self.permissions = permissions
  }

  func openReleaseNotes() {
    let releaseNotes = ReleaseNotes()
    releaseNotes.open()
    self.releaseNotes = releaseNotes
  }

  func openEmptyConfig() {
    let emptyConfig = EmptyConfiguration(store: core.contentStore)
    emptyConfig.open()
    self.emptyConfig = emptyConfig
  }

  func openNewCommandWindow(_ context: NewCommandScene.Context) {
    let window = NewCommandWindow(
      context: context,
      contentStore: core.contentStore,
      uiElementCaptureStore: core.uiElementCaptureStore,
      configurationPublisher: core.configCoordinator.configurationPublisher) { [core] workflowId, commandId, title, payload in
        let groupIds = core.groupSelectionManager.selections
        Task {
          await core.detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                          title: title, commandId: commandId)
          core.contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId]))
          core.contentCoordinator.handle(.refresh(groupIds))
        }
      }
    window.open()
    self.newCommandWindow = window
  }
}
