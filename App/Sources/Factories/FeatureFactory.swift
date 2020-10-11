import Foundation
import LogicFramework
import ViewKit

class FeatureFactory {
  private let logic = ControllerFactory()
  private let mapperFactory: ViewModelMapperFactory
  private let coreController: CoreControlling
  private let userSelection: UserSelection
  private var groupsController: GroupsControlling {
    coreController.groupsController
  }
  private var groups: [Group] { coreController.groups }
  private var installedApplications: [Application] {
    coreController.installedApplications
  }

  init(coreController: CoreControlling, userSelection: UserSelection) {
    self.coreController = coreController
    self.userSelection = userSelection
    self.mapperFactory = ViewModelMapperFactory(installedApplications: coreController.installedApplications)
  }

  func groupFeature() -> GroupsFeatureController {
    let controller = GroupsFeatureController(
      groupsController: groupsController,
      userSelection: userSelection,
      mapper: mapperFactory.groupMapper()
    )

    controller.applications = installedApplications

    return controller
  }

  func workflowFeature() -> WorkflowFeatureController {
    WorkflowFeatureController(
      state: WorkflowViewModel(
        id: "", name: "",
        keyboardShortcuts: [], commands: []),
      groupsController: groupsController,
      userSelection: userSelection)
  }

  func commandsFeature() -> CommandsFeatureController {
    CommandsFeatureController(groupsController: groupsController,
                              installedApplications: installedApplications,
                              state: [], userSelection: userSelection)
  }
}
