import Cocoa
import Combine
import DirectoryObserver
import LaunchArguments
import LogicFramework
import SwiftUI
import ViewKit
import ModelKit

let bundleIdentifier = Bundle.main.bundleIdentifier!
let launchArguments = LaunchArgumentsController<LaunchArgument>()

class AppDelegate: NSObject, NSApplicationDelegate,
                   NSWindowDelegate, MenubarControllerDelegate {
  static let enableNotification = Notification.Name("enableHotKeys")
  static let disableNotification = Notification.Name("disableHotKeys")

  weak var window: NSWindow?
  var cancellables = Set<AnyCancellable>()
  var shouldOpenMainWindow = launchArguments.isEnabled(.openWindowAtLaunch)
  var coreController: CoreControlling?
  let factory = ControllerFactory()
  var groupFeatureController: GroupsFeatureController?
  var directoryObserver: DirectoryObserver?
  var menubarController: MenubarController?
  static var internalChange: Bool = false

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

    NotificationCenter.default.addObserver(self, selector: #selector(enableHotKeys),
                                           name: Self.enableNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disableHotKeys),
                                           name: Self.disableNotification, object: nil)

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

  // MARK: Notifications

  @objc private func enableHotKeys() {
    if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
      coreController?.disableKeyboardShortcuts = false
    }
  }

  @objc private func disableHotKeys() {
    if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
      coreController?.disableKeyboardShortcuts = true
    }
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

    let mainView = context.factory.mainView()
      .environmentObject(userSelection)

    let window = featureFactory.mainWindow(autosaveName: "Main Window") { [weak self] in
      self?.groupFeatureController = nil
      self?.window = nil
    }
    window.delegate = self
    window.contentView = NSHostingView(rootView: mainView)

    self.groupFeatureController = context.groupsFeature

    context.groupsFeature.subject
      .debounce(for: 0.5, scheduler: RunLoop.main)
      .throttle(for: 2.0, scheduler: RunLoop.main, latest: true)
      .removeDuplicates()
      .receive(on: DispatchQueue.global(qos: .userInitiated))
      .sink(receiveValue: { groups in
        self.saveGroupsToDisk(groups)
    })
      .store(in: &cancellables)

    configureDirectoryObserver(coreController)

    return window
  }

  private func configureDirectoryObserver(_ coreController: CoreControlling) {
    directoryObserver = DirectoryObserver(at: URL(fileURLWithPath: storageController.path)) { [weak self] in
      guard let self = self,
            let groups = try? self.storageController.load(),
            !Self.internalChange else { return }
      coreController.groupsController.reloadGroups(groups)
      self.groupFeatureController?.state = groups
    }
  }

  private func saveGroupsToDisk(_ groups: [ModelKit.Group]) {
    do {
      Self.internalChange = true
      try storageController.save(groups)
      /// **TODO**
      ///
      /// - Important: Remove this delay and implement a proper way to enable and disable
      ///              listening to file system events.
      /// - https://github.com/zenangst/KeyboardCowboy/issues/143
      DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
        Self.internalChange = false
      })
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
  }
}
