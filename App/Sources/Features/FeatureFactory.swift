import Foundation
import LogicFramework
import ModelKit
import ViewKit
import SwiftUI

class FeatureContext {
  var applicationProvider: ApplicationsProvider
  let applicationTrigger: ApplicationTriggerFeatureController
  let commands: CommandsFeatureController
  let groups: GroupsFeatureController
  let keyboardsShortcuts: KeyboardShortcutsFeatureController
  let openPanel: OpenPanelController
  let search: SearchFeatureController
  let workflow: WorkflowFeatureController
  let workflows: WorkflowsFeatureController

  init(applicationProvider: ApplicationsProvider,
       applicationTrigger: ApplicationTriggerFeatureController,
       commandFeature: CommandsFeatureController,
       groupsFeature: GroupsFeatureController,
       keyInputSubjectWrapper: KeyInputSubjectWrapper,
       keyboardFeature: KeyboardShortcutsFeatureController,
       openPanel: OpenPanelController,
       searchFeature: SearchFeatureController,
       workflowFeature: WorkflowFeatureController,
       workflowsFeature: WorkflowsFeatureController) {
    self.applicationProvider = applicationProvider
    self.applicationTrigger = applicationTrigger
    self.commands = commandFeature
    self.groups = groupsFeature
    self.keyboardsShortcuts = keyboardFeature
    self.openPanel = openPanel
    self.search = searchFeature
    self.workflow = workflowFeature
    self.workflows = workflowsFeature
  }

  func viewKitContext(keyInputSubjectWrapper: KeyInputSubjectWrapper) -> ViewKitFeatureContext {
    ViewKitFeatureContext(applicationProvider: applicationProvider.erase(),
                          applicationTrigger: applicationTrigger.erase(),
                          commands: commands.erase(),
                          groups: groups.erase(),
                          keyInputSubjectWrapper: keyInputSubjectWrapper,
                          keyboardsShortcuts: keyboardsShortcuts.erase(),
                          openPanel: openPanel.erase(),
                          search: search.erase(),
                          workflow: workflow.erase(),
                          workflows: workflows.erase())
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
    let applicationTrigger = ApplicationTriggerFeatureController()
    let commandsController = commandsFeature(commandController: coreController.commandController)
    let openPanelController = OpenPanelViewController()
    let groupFeatureController = groupFeature()
    let keyboardController = keyboardShortcutFeature()
    let searchController = searchFeature()
    let workflowController = workflowFeature()
    let workflowsController = workflowsFeature(
      workflowController: workflowController.erase())

    workflowsController.delegate = groupFeatureController
    applicationTrigger.delegate = workflowsController
    keyboardController.delegate = workflowsController
    commandsController.delegate = workflowsController
    workflowController.delegate = workflowsController

    return FeatureContext(applicationProvider: applicationProvider,
                          applicationTrigger: applicationTrigger,
                          commandFeature: commandsController,
                          groupsFeature: groupFeatureController,
                          keyInputSubjectWrapper: keyInputSubjectWrapper,
                          keyboardFeature: keyboardController,
                          openPanel: openPanelController.erase(),
                          searchFeature: searchController,
                          workflowFeature: workflowController,
                          workflowsFeature: workflowsController)
  }

  func groupFeature() -> GroupsFeatureController {
    GroupsFeatureController(
      groupsController: groupsController,
      applications: installedApplications
    )
  }

  func workflowFeature() -> WorkflowFeatureController {
    WorkflowFeatureController()
  }

  func workflowsFeature(workflowController: WorkflowController) -> WorkflowsFeatureController {
    WorkflowsFeatureController(applications: installedApplications,
                               workflowController: workflowController)
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
