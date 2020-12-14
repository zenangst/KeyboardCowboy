import Foundation
import LogicFramework
import ModelKit
import ViewKit
import SwiftUI

class FeatureContext {
  var applicationProvider: ApplicationsProvider
  let commands: CommandsFeatureController
  let groups: GroupsFeatureController
  let keyboardsShortcuts: KeyboardShortcutsFeatureController
  let openPanel: OpenPanelController
  let search: SearchFeatureController
  let workflow: WorkflowFeatureController

  init(applicationProvider: ApplicationsProvider,
       commandFeature: CommandsFeatureController,
       groupsFeature: GroupsFeatureController,
       keyInputSubjectWrapper: KeyInputSubjectWrapper,
       keyboardFeature: KeyboardShortcutsFeatureController,
       openPanel: OpenPanelController,
       searchFeature: SearchFeatureController,
       workflowFeature: WorkflowFeatureController) {
    self.applicationProvider = applicationProvider
    self.commands = commandFeature
    self.groups = groupsFeature
    self.keyboardsShortcuts = keyboardFeature
    self.openPanel = openPanel
    self.search = searchFeature
    self.workflow = workflowFeature
  }

  func viewKitContext(keyInputSubjectWrapper: KeyInputSubjectWrapper) -> ViewKitFeatureContext {
    ViewKitFeatureContext.init(applicationProvider: applicationProvider.erase(),
                               commands: commands.erase(),
                               groups: groups.erase(),
                               keyInputSubjectWrapper: keyInputSubjectWrapper,
                               keyboardsShortcuts: keyboardsShortcuts.erase(),
                               openPanel: openPanel.erase(),
                               search: search.erase(),
                               workflow: workflow.erase())
  }
}

final class FeatureFactory {
  private let coreController: CoreControlling
  private var groupsController: GroupsControlling {
    coreController.groupsController
  }
  private var installedApplications: [Application] {
    coreController.installedApplications
  }

  init(coreController: CoreControlling) {
    self.coreController = coreController
  }

  static func menuBar() -> MenubarController {
    MenubarController()
  }

  func featureContext(keyInputSubjectWrapper: KeyInputSubjectWrapper) -> FeatureContext {
    let applicationProvider = ApplicationsProvider(applications: coreController.installedApplications)
    let commandsController = commandsFeature(commandController: coreController.commandController)
    let openPanelController = OpenPanelViewController()
    let groupFeatureController = groupFeature()
    let keyboardController = keyboardShortcutFeature()
    let searchController = searchFeature()
    let workflowController = workflowFeature()

    workflowController.delegate = groupFeatureController
    keyboardController.delegate = workflowController
    commandsController.delegate = workflowController

    return FeatureContext(applicationProvider: applicationProvider,
                          commandFeature: commandsController,
                          groupsFeature: groupFeatureController,
                          keyInputSubjectWrapper: keyInputSubjectWrapper,
                          keyboardFeature: keyboardController,
                          openPanel: openPanelController.erase(),
                          searchFeature: searchController,
                          workflowFeature: workflowController)
  }

  func groupFeature() -> GroupsFeatureController {
    GroupsFeatureController(
      groupsController: groupsController,
      applications: installedApplications
    )
  }

  func workflowFeature() -> WorkflowFeatureController {
    WorkflowFeatureController(applications: installedApplications)
  }

  func keyboardShortcutFeature() -> KeyboardShortcutsFeatureController {
    KeyboardShortcutsFeatureController()
  }

  func commandsFeature(commandController: CommandControlling) -> CommandsFeatureController {
    CommandsFeatureController(
      commandController: commandController,
      groupsController: groupsController,
      installedApplications: installedApplications)
  }

  func searchFeature() -> SearchFeatureController {
    let root = SearchRootController(groupsController: groupsController,
                                    groupSearch: SearchGroupsController())
    let feature = SearchFeatureController(
      groupController: groupsController,
      searchController: root,
      query: .constant(""))
    return feature
  }
}
