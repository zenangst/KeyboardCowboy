import Cocoa
import LaunchArguments
import LogicFramework

class AppDelegate: NSObject, NSApplicationDelegate {
  var controller: CoreControlling?
  let launchArgumentsController = LaunchArgumentsController<LaunchArgument>()
  let factory = ControllerFactory()

  func applicationDidFinishLaunching(_ notification: Notification) {
    if launchArgumentsController.isEnabled(.runningUnitTests) { return }

    runApplication()
  }

  private func runApplication() {
    let storageController = factory.storageController(path: "~", fileName: ".keyboard-cowboy.json")
    do {
      let groups = try storageController.load()
      let groupsController = factory.groupsController(groups: groups)
      let controller = factory.coreController(
        groupsController: groupsController
      )
      self.controller = controller
    } catch let error {
      let alert = NSAlert()
      alert.messageText = error.localizedDescription
      if case .dataCorrupted(let context) = error as? DecodingError {
        alert.informativeText = context.underlyingError?.localizedDescription ?? ""
        alert.messageText = context.debugDescription
      }
      alert.runModal()
    }
  }
}
