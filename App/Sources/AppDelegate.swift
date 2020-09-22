import Cocoa
import LogicFramework

class AppDelegate: NSObject, NSApplicationDelegate {
  var controller: CoreControlling?
  let factory = ControllerFactory()

  func applicationDidFinishLaunching(_ notification: Notification) {
    let storageController = factory.storageController(path: "~", fileName: ".keyboard-cowboy.json")
    do {
      let groups = try storageController.load()
      let groupsController = factory.groupsController(groups: groups)
      let controller = factory.coreController(
        groupsController: groupsController
      )
      self.controller = controller
    } catch let error {
      assertionFailure(error.localizedDescription)
    }
  }
}
