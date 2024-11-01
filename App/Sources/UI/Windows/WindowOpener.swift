import AppKit
import SwiftUI

@MainActor
final class WindowOpener: ObservableObject {
  private let core: Core

  init(core: Core) {
    self.core = core

    NotificationCenter.default.addObserver(self, selector: #selector(openMainWindow), name: .openKeyboardCowboy, object: nil)
  }

  @objc func openMainWindow() {
    MainWindow(core: core).open()
  }

  func openGroup(_ context: GroupWindow.Context) {
    GroupWindow(
      context: context,
      applicationStore: ApplicationStore.shared,
      configurationPublisher: core.configCoordinator.configurationPublisher,
      contentPublisher: core.contentCoordinator.contentPublisher,
      contentCoordinator: core.contentCoordinator,
      sidebarCoordinator: core.sidebarCoordinator
    )
      .open(context)
  }

  func openPermissions() {
    Permissions().open()
  }

  func openReleaseNotes() {
    ReleaseNotes().open()
  }

  func openEmptyConfig() {
    EmptyConfiguration(store: core.contentStore).open()
  }

  func openNewCommandWindow(_ context: NewCommandWindow.Context) {
    NewCommandWindow(
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
      }.open()
  }
}
