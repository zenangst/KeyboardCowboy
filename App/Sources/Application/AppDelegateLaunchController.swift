import Cocoa
import LaunchArguments
import LogicFramework

class AppDelegateLaunchController {
  let factory = ControllerFactory()

  func initialLoad(storageController: StorageControlling) throws -> CoreControlling {
    let groups = try storageController.load()
    let groupsController = factory.groupsController(groups: groups)
    let controller = factory.coreController(
      disableKeyboardShortcuts: launchArguments.isEnabled(.disableKeyboardShortcuts),
      groupsController: groupsController)
    return controller
  }
}
