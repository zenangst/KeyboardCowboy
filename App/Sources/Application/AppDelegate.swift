import Cocoa
import LaunchArguments
import LogicFramework
import SwiftUI
import ViewKit

let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"]!
let launchArguments = LaunchArgumentsController<LaunchArgument>()

class AppDelegate: NSObject, NSApplicationDelegate, GroupsFeatureControllerDelegate {
  var window: NSWindow?
  var controller: CoreControlling?
  let factory = ControllerFactory()
  var groupFeatureController: GroupsFeatureController?
  var viewModelFactory = ViewModelMapperFactory()
  var workflowFeatureController: WorkflowFeatureController?

  var storageController: StorageControlling {
    let path: String
    let fileName: String

    if launchArguments.isEnabled(.demoMode) {
      path = sourceRoot
      fileName = "keyboard-cowboy.json"
    } else {
      path = "~"
      fileName = ".keyboard-cowboy.json"
    }

    return factory.storageController(path: path, fileName: fileName)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if launchArguments.isEnabled(.runningUnitTests) { return }
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil { return }

    runApplication()
  }

  private func runApplication() {
    do {
      let launchController = AppDelegateLaunchController()
      let controller = try launchController.initialLoad(storageController: storageController)
      self.controller = controller

      if launchArguments.isEnabled(.runWindowless) { return }

      self.window = createMainWindow(controller)
      self.window?.makeKeyAndOrderFront(nil)
      self.controller?.disableKeyboardShortcuts = true
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  private func createMainWindow(_ coreController: CoreControlling) -> NSWindow? {
    let userSelection  = UserSelection()
    let featureFactory = FeatureFactory(coreController: coreController,
                                        userSelection: userSelection)
    let groupFeatureController = featureFactory.groupFeature()
    groupFeatureController.delegate = self

    let workflowFeatureController = featureFactory.workflowFeature()
    workflowFeatureController.delegate = groupFeatureController

    let commandsController = featureFactory.commandsFeature()

    commandsController.delegate = workflowFeatureController

    let applicationProvider = ApplicationsProvider(applications: coreController.installedApplications,
                                                   mapper: viewModelFactory.applicationMapper())

    let groupList = MainView(
      applicationProvider: applicationProvider.erase(),
      commandController: commandsController.erase(),
      groupController: groupFeatureController.erase(),
      openPanelController: OpenPanelViewController().erase(),
      workflowController: workflowFeatureController.erase())
      .environmentObject(userSelection)
    let window = MainWindow(toolbar: Toolbar())

    window.title = "Keyboard Cowboy"
    window.contentView = NSHostingView(rootView: groupList)
    window.setFrameAutosaveName("Main Window")

    self.groupFeatureController = groupFeatureController

    return window
  }

  // MARK: GroupsFeatureControllerDelegate

  func groupsFeatureController(_ controller: GroupsFeatureController,
                               didReloadGroups groups: [LogicFramework.Group]) {
    do {
      try storageController.save(groups)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }
}
