import Cocoa
import LogicFramework

class AppDelegateLaunchController {
  let factory = ControllerFactory()

  func initialLoad() throws -> CoreControlling {
    let storageController = factory.storageController(path: "~", fileName: ".keyboard-cowboy.json")
    let groups = try storageController.load()
    let groupsController = factory.groupsController(groups: groups)
    let controller = factory.coreController(groupsController: groupsController)
    return controller
  }
}
