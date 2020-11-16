import SwiftUI
import ModelKit

public protocol ViewFactory {
  func mainView() -> MainView
  func groupList() -> GroupList
  func workflowList(group: ModelKit.Group) -> WorkflowList
  func workflowDetail(_ workflow: ModelKit.Workflow, group: ModelKit.Group) -> WorkflowView
}

public class DesignTimeFactory: ViewFactory {
  let applicationProvider = ApplicationPreviewProvider().erase()
  let commandController = CommandPreviewController().erase()
  let groupController = GroupPreviewController().erase()
  let keyboardShortcutController = KeyboardShortcutPreviewController().erase()
  let openPanelController = OpenPanelPreviewController().erase()
  let searchController = SearchPreviewController().erase()
  let workflowController = WorkflowPreviewController().erase()

  public func mainView() -> MainView {
    MainView(factory: self,
             applicationProvider: applicationProvider,
             commandController: commandController,
             groupController: groupController,
             openPanelController: openPanelController,
             searchController: searchController,
             workflowController: workflowController)
  }

  public func groupList() -> GroupList {
    GroupList(applicationProvider: applicationProvider,
              factory: self,
              groupController: groupController,
              workflowController: workflowController)
  }

  public func workflowList(group: ModelKit.Group) -> WorkflowList {
    WorkflowList(factory: self, group: ModelFactory().groupList().first!,
                 workflowController: workflowController)
  }

  public func workflowDetail(_ workflow: Workflow, group: ModelKit.Group) -> WorkflowView {
    WorkflowView(workflow: ModelFactory().workflowDetail(),
                 group: ModelFactory().groupList().first!,
                 applicationProvider: applicationProvider,
                 commandController: commandController,
                 keyboardShortcutController: keyboardShortcutController,
                 openPanelController: openPanelController,
                 workflowController: workflowController)
  }
}

public class AppViewFactory: ViewFactory {
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let groupController: GroupController
  let keyboardShortcutController: KeyboardShortcutController
  let openPanelController: OpenPanelController
  let searchController: SearchController
  let userSelection: UserSelection
  let workflowController: WorkflowController

  public init(applicationProvider: ApplicationProvider,
              commandController: CommandController,
              groupController: GroupController,
              keyboardShortcutController: KeyboardShortcutController,
              openPanelController: OpenPanelController,
              searchController: SearchController,
              userSelection: UserSelection,
              workflowController: WorkflowController) {
    self.applicationProvider = applicationProvider
    self.commandController = commandController
    self.groupController = groupController
    self.keyboardShortcutController = keyboardShortcutController
    self.openPanelController = openPanelController
    self.searchController = searchController
    self.workflowController = workflowController
    self.userSelection = userSelection
  }

  public func mainView() -> MainView {
    MainView(factory: self,
             applicationProvider: applicationProvider,
             commandController: commandController,
             groupController: groupController,
             openPanelController: openPanelController,
             searchController: searchController,
             workflowController: workflowController)
  }

  public func groupList() -> GroupList {
    GroupList(
      applicationProvider: applicationProvider,
      factory: self,
      groupController: groupController,
      workflowController: workflowController)
  }

  public func workflowList(group: ModelKit.Group) -> WorkflowList {
    WorkflowList(factory: self, group: group, workflowController: workflowController)
  }

  public func workflowDetail(_ workflow: ModelKit.Workflow, group: ModelKit.Group) -> WorkflowView {
    WorkflowView(
      workflow: workflow,
      group: group,
      applicationProvider: applicationProvider,
      commandController: commandController,
      keyboardShortcutController: keyboardShortcutController,
      openPanelController: openPanelController,
      workflowController: workflowController)
  }
}
