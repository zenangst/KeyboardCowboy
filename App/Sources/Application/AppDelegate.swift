import Cocoa
import DirectoryObserver
import LaunchArguments
import LogicFramework
import SwiftUI
import ViewKit
import ModelKit

let launchArguments = LaunchArgumentsController<LaunchArgument>()

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate,
                   GroupsFeatureControllerDelegate, MenubarControllerDelegate {
  weak var window: NSWindow?
  var shouldOpenMainWindow = launchArguments.isEnabled(.openWindowAtLaunch)
  var coreController: CoreControlling?
  let factory = ControllerFactory()
  var groupFeatureController: GroupsFeatureController?
  var directoryObserver: DirectoryObserver?
  var menubarController: MenubarController?

  var storageController: StorageControlling {
    let configuration = Configuration.Storage()
    return factory.storageController(path: configuration.path,
                                     fileName: configuration.fileName)
  }

  // MARK: Application life cycle

  func applicationDidFinishLaunching(_ notification: Notification) {
    if launchArguments.isEnabled(.runningUnitTests) { return }
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil { return }

    Debug.isEnabled = launchArguments.isEnabled(.debug)

    runApplication()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if window == nil, let coreController = coreController {
      createAndOpenWindow(coreController)
    }
    return true
  }

  func applicationWillBecomeActive(_ notification: Notification) {
    if shouldOpenMainWindow, window == nil,
       let coreController = coreController {
      createAndOpenWindow(coreController)
    }

    shouldOpenMainWindow = true
  }

  // MARK: Private methods

  private func createAndOpenWindow(_ coreController: CoreControlling) {
    let window = createMainWindow(coreController)
    window?.makeKeyAndOrderFront(NSApp)
    self.window = window
  }

  private func runApplication() {
    do {
      let launchController = AppDelegateLaunchController(factory: factory)
      let coreController = try launchController.initialLoad(storageController: storageController)
      self.coreController = coreController

      let featureFactory = FeatureFactory(coreController: coreController)
      let menubarController = featureFactory.menuBar()
      menubarController.delegate = self
      self.menubarController = menubarController

    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  private func createMainWindow(_ coreController: CoreControlling) -> NSWindow? {
    IconController.installedApplications = coreController.installedApplications
    let userSelection = UserSelection()
    let featureFactory = FeatureFactory(coreController: coreController)
    let context = featureFactory.applicationStack(userSelection: userSelection)

    userSelection.group = context.groupsFeature.state.first
    userSelection.workflow = context.groupsFeature.state.first?.workflows.first

    let mainView = MainView(
      applicationProvider: context.applicationProvider.erase(),
      commandController: context.commandFeature.erase(),
      groupController: context.groupsFeature.erase(),
      keyboardShortcutController: context.keyboardFeature.erase(),
      openPanelController: OpenPanelViewController().erase(),
      searchController: context.searchFeature.erase(),
      workflowController: context.workflowFeature.erase())
      .environmentObject(userSelection)

    let window = featureFactory.mainWindow(autosaveName: "Main Window") { [weak self] in
      self?.groupFeatureController = nil
      self?.window = nil
    }
    window.delegate = self
    window.contentView = NSHostingView(rootView: mainView)

    context.groupsFeature.delegate = self
    self.groupFeatureController = context.groupsFeature

    configureDirectoryObserver(coreController)

    return window
  }

  private func configureDirectoryObserver(_ coreController: CoreControlling) {
    directoryObserver = DirectoryObserver(at: URL(fileURLWithPath: storageController.path)) { [weak self] in
      guard let self = self,
            let groups = try? self.storageController.load() else { return }
      coreController.groupsController.reloadGroups(groups)

      self.groupFeatureController?.state = groups
    }
  }

  // MARK: GroupsFeatureControllerDelegate

  func groupsFeatureController(_ controller: GroupsFeatureController,
                               didReloadGroups groups: [ModelKit.Group]) {
    do {
      try storageController.save(groups)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  // MARK: MenubarControllerDelegate

  func menubarController(_ controller: MenubarController, didTapOpenApplication openApplicationMenuItem: NSMenuItem) {
    if let window = window {
      window.makeKeyAndOrderFront(NSApp)
    } else if window == nil, let coreController = coreController {
      createAndOpenWindow(coreController)
    }
    NSApp.activate(ignoringOtherApps: true)
  }

  // MARK: NSWindowDelegate

  func windowWillClose(_ notification: Notification) {
    menubarController?.setState(.inactive)
    IconController.clearAll()
  }

  func windowDidBecomeKey(_ notification: Notification) {
    menubarController?.setState(.active)

    if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
      coreController?.disableKeyboardShortcuts = true
    }
  }

  func windowDidResignKey(_ notification: Notification) {
    if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
      coreController?.disableKeyboardShortcuts = false
    }
  }
}
