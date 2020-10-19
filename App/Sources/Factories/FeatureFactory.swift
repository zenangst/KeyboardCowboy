import Foundation
import LogicFramework
import ViewKit
import ModelKit

class FeatureFactory {
  private let coreController: CoreControlling
  private let userSelection: UserSelection
  private var groupsController: GroupsControlling {
    coreController.groupsController
  }
  private var groups: [Group] { coreController.groups }
  private var installedApplications: [Application] {
    coreController.installedApplications
  }

  init(coreController: CoreControlling,
       userSelection: UserSelection) {
    self.coreController = coreController
    self.userSelection = userSelection
  }

  func groupFeature() -> GroupsFeatureController {
    let controller = GroupsFeatureController(
      groupsController: groupsController,
      userSelection: userSelection
    )

    controller.applications = installedApplications

    return controller
  }

  func workflowFeature() -> WorkflowFeatureController {
    WorkflowFeatureController(
      state: Workflow(
        id: "", name: "",
        keyboardShortcuts: [], commands: []),
      groupsController: groupsController,
      userSelection: userSelection)
  }

  func keyboardShortcutFeature() -> KeyboardShortcutsFeatureController {
    KeyboardShortcutsFeatureController(groupsController: groupsController,
                                       state: [],
                                       userSelection: userSelection)
  }

  func commandsFeature() -> CommandsFeatureController {
    CommandsFeatureController(groupsController: groupsController,
                              installedApplications: installedApplications,
                              state: [], userSelection: userSelection)
  }

  func searchFeature(userSelection: UserSelection) -> SearchFeatureController {
    let root = SearchRootController(groupsController: groupsController,
                                    groupSearch: SearchGroupsController())
    let feature = SearchFeatureController(userSelection: userSelection,
                                          searchController: root,
                                          query: .constant(""))
    return feature
  }
}
