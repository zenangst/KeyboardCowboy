import Foundation
import LogicFramework
import ViewKit
import ModelKit

typealias ApplicationStackContext = (applicationProvider: ApplicationsProvider,
                                     commandFeature: CommandsFeatureController,
                                     groupsFeature: GroupsFeatureController,
                                     keyboardFeature: KeyboardShortcutsFeatureController,
                                     searchFeature: SearchFeatureController,
                                     workflowFeature: WorkflowFeatureController)

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

  func mainWindow(autosaveName: String, _ onClose: @escaping () -> Void) -> Window {
    let window = Window(autosaveName: autosaveName,
                        toolbar: Toolbar(),
                        onClose: onClose)
    window.title = ProcessInfo.processInfo.processName
    window.setFrameAutosaveName(autosaveName)
    return window
  }

  func menuBar() -> MenubarController {
    MenubarController()
  }

  func applicationStack() -> ApplicationStackContext {
    let groupFeatureController = groupFeature()

    let workflowFeatureController = workflowFeature()
    workflowFeatureController.delegate = groupFeatureController

    let keyboardFeatureController = keyboardShortcutFeature()
    keyboardFeatureController.delegate = workflowFeatureController

    let commandsController = commandsFeature()
    commandsController.delegate = workflowFeatureController

    let applicationProvider = ApplicationsProvider(applications: coreController.installedApplications)

    let searchFeatureController = searchFeature(userSelection: userSelection)

    return (applicationProvider: applicationProvider,
            commandFeature: commandsController,
            groupsFeature: groupFeatureController,
            keyboardFeature: keyboardFeatureController,
            searchFeature: searchFeatureController,
            workflowFeature: workflowFeatureController)
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
