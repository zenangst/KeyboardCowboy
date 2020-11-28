import Foundation
import LogicFramework
import ModelKit
import ViewKit

final class FeatureFactory {
  private let coreController: CoreControlling
  private var groupsController: GroupsControlling {
    coreController.groupsController
  }
  private var groups: [Group] { coreController.groups }
  private var installedApplications: [Application] {
    coreController.installedApplications
  }

  init(coreController: CoreControlling) {
    self.coreController = coreController
  }

  func menuBar() -> MenubarController {
    MenubarController()
  }

  // swiftlint:disable large_tuple
  func applicationStack(userSelection: UserSelection) -> (applicationProvider: ApplicationsProvider,
                                                          commandFeature: CommandsFeatureController,
                                                          factory: ViewFactory,
                                                          groupsFeature: GroupsFeatureController,
                                                          keyboardFeature: KeyboardShortcutsFeatureController,
                                                          searchFeature: SearchFeatureController,
                                                          workflowFeature: WorkflowFeatureController) {
    let applicationProvider = ApplicationsProvider(applications: coreController.installedApplications)
    let commandsController = commandsFeature(commandController: coreController.commandController)
    let groupFeatureController = groupFeature(userSelection: userSelection)
    let keyboardController = keyboardShortcutFeature()
    let searchController = searchFeature(userSelection: userSelection)
    let workflowController = workflowFeature()

    workflowController.delegate = groupFeatureController
    keyboardController.delegate = workflowController
    commandsController.delegate = workflowController

    let factory = AppViewFactory(applicationProvider: applicationProvider.erase(),
                                 commandController: commandsController.erase(),
                                 groupController: groupFeatureController.erase(),
                                 keyboardShortcutController: keyboardController.erase(),
                                 openPanelController: OpenPanelViewController().erase(),
                                 searchController: searchController.erase(),
                                 userSelection: userSelection,
                                 workflowController: workflowController.erase())

    return (applicationProvider: applicationProvider,
            commandFeature: commandsController,
            factory: factory,
            groupsFeature: groupFeatureController,
            keyboardFeature: keyboardController,
            searchFeature: searchController,
            workflowFeature: workflowController)
  }

  func groupFeature(userSelection: UserSelection) -> GroupsFeatureController {
    GroupsFeatureController(
      groupsController: groupsController,
      applications: installedApplications,
      userSelection: userSelection
    )
  }

  func workflowFeature() -> WorkflowFeatureController {
    WorkflowFeatureController(
      state: Workflow(
        id: "", name: "",
        keyboardShortcuts: [], commands: []),
      applications: installedApplications,
      groupsController: groupsController)
  }

  func keyboardShortcutFeature() -> KeyboardShortcutsFeatureController {
    KeyboardShortcutsFeatureController(groupsController: groupsController)
  }

  func commandsFeature(commandController: CommandControlling) -> CommandsFeatureController {
    CommandsFeatureController(
      commandController: commandController,
      groupsController: groupsController,
      installedApplications: installedApplications)
  }

  func searchFeature(userSelection: UserSelection) -> SearchFeatureController {
    let root = SearchRootController(groupsController: groupsController,
                                    groupSearch: SearchGroupsController())
    let feature = SearchFeatureController(searchController: root,
                                          groupController: groupsController,
                                          query: .constant(""),
                                          userSelection: userSelection)
    return feature
  }
}
