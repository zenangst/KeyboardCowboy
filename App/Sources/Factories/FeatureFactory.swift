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

  // swiftlint:disable large_tuple
  func applicationStack(userSelection: UserSelection) -> (applicationProvider: ApplicationsProvider,
                                                          commandFeature: CommandsFeatureController,
                                                          groupsFeature: GroupsFeatureController,
                                                          keyboardFeature: KeyboardShortcutsFeatureController,
                                                          searchFeature: SearchFeatureController,
                                                          workflowFeature: WorkflowFeatureController) {
    let groupFeatureController = groupFeature(userSelection: userSelection)

    let workflowFeatureController = workflowFeature()
    workflowFeatureController.delegate = groupFeatureController

    let keyboardFeatureController = keyboardShortcutFeature()
    keyboardFeatureController.delegate = workflowFeatureController

    let commandsController = commandsFeature()
    commandsController.delegate = workflowFeatureController

    let applicationProvider = ApplicationsProvider(applications: coreController.installedApplications)

    let searchFeatureController = searchFeature()

    return (applicationProvider: applicationProvider,
            commandFeature: commandsController,
            groupsFeature: groupFeatureController,
            keyboardFeature: keyboardFeatureController,
            searchFeature: searchFeatureController,
            workflowFeature: workflowFeatureController)
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
      groupsController: groupsController)
  }

  func keyboardShortcutFeature() -> KeyboardShortcutsFeatureController {
    KeyboardShortcutsFeatureController(groupsController: groupsController)
  }

  func commandsFeature() -> CommandsFeatureController {
    CommandsFeatureController(groupsController: groupsController,
                              installedApplications: installedApplications)
  }

  func searchFeature() -> SearchFeatureController {
    let root = SearchRootController(groupsController: groupsController,
                                    groupSearch: SearchGroupsController())
    let feature = SearchFeatureController(searchController: root,
                                          query: .constant(""))
    return feature
  }
}
