import Cocoa
import LaunchArguments
import LogicFramework
import SwiftUI
import ViewKit

class AppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow?
  var controller: CoreControlling?

  let launchController = AppDelegateLaunchController()
  let launchArgumentsController = LaunchArgumentsController<LaunchArgument>()

  func applicationDidFinishLaunching(_ notification: Notification) {
    if launchArgumentsController.isEnabled(.runningUnitTests) { return }

    runApplication()
  }

  private func runApplication() {
    do {
      let controller = try launchController.initialLoad()
      self.controller = controller

      if launchArgumentsController.isEnabled(.runWindowless) { return }

      self.window = createMainWindow(controller)
      self.window?.makeKeyAndOrderFront(nil)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  private func createMainWindow(_ controller: CoreControlling) -> NSWindow? {
    let models = GroupViewModelMapper().map(controller.groups).sorted(by: { $0.name < $1.name })
    let groupListController = GroupListController(groups: models)
    let groupList = GroupList(controller: groupListController.erase())
    let window = MainWindow(toolbar: Toolbar())

    window.title = "Keyboard Cowboy"
    window.contentView = NSHostingView(rootView: groupList)
    window.setFrameAutosaveName("Main Window")

    return window
  }
}
