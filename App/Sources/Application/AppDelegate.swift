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
                   MenubarControllerDelegate,
                   NSWindowDelegate {
  static let enableNotification = Notification.Name("enableHotKeys")
  static let disableNotification = Notification.Name("disableHotKeys")

  @Published var mainView: MainView?
  @Published var windowIsOpened: Bool = true
  let factory = ControllerFactory()
  static var internalChange: Bool = false
  var cancellables = Set<AnyCancellable>()
  var coreController: CoreControlling?
  var directoryObserver: DirectoryObserver?
  var groupFeatureController: GroupsFeatureController?
  var menubarController: MenubarController?
  var userSelection = UserSelection()

  var storageController: StorageControlling {
    let configuration = Configuration.Storage()
    return factory.storageController(path: configuration.path,
                                     fileName: configuration.fileName)
  }

  override init() {
    super.init()
    windowIsOpened = launchArguments.isEnabled(.openWindowAtLaunch)
  }

  // MARK: Application life cycle

  func applicationWillFinishLaunching(_ notification: Notification) {
    if launchArguments.isEnabled(.runningUnitTests) { return }
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil { return }

    Debug.isEnabled = launchArguments.isEnabled(.debug)

    NotificationCenter.default.addObserver(self, selector: #selector(enableHotKeys),
                                           name: Self.enableNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disableHotKeys),
                                           name: Self.disableNotification, object: nil)
    runApplication()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    windowIsOpened = true
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    return true
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

  private func runApplication() {
    do {
      let launchController = AppDelegateLaunchController(factory: factory)
      let coreController = try launchController.initialLoad(storageController: storageController)
      self.coreController = coreController
      self.mainView = createMainView(coreController)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  @discardableResult
  func createMainView(_ coreController: CoreControlling) -> MainView {
    IconController.installedApplications = coreController.installedApplications
    let featureFactory = FeatureFactory(coreController: coreController)
    let context = featureFactory.applicationStack(userSelection: userSelection)

    let mainView = context.factory.mainView()
    self.groupFeatureController = context.groupsFeature

    let menubarController = featureFactory.menuBar()
    menubarController.delegate = self
    self.menubarController = menubarController

    context.groupsFeature.subject
      .debounce(for: 0.5, scheduler: RunLoop.main)
      .throttle(for: 2.0, scheduler: RunLoop.main, latest: true)
      .removeDuplicates()
      .receive(on: DispatchQueue.global(qos: .userInitiated))
      .sink { self.saveGroupsToDisk($0) }
      .store(in: &cancellables)

    configureDirectoryObserver(coreController)
    return mainView
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

  // MARK: NSWindowDelegate

  func windowWillClose(_ notification: Notification) {
    menubarController?.setState(.inactive)
    IconController.clearAll()
  }

  func windowDidBecomeKey(_ notification: Notification) {
    menubarController?.setState(.active)
  }

  // MARK: MenubarControllerDelegate

    func menubarController(_ controller: MenubarController, didTapOpenApplication openApplicationMenuItem: NSMenuItem) {
      NSApp.activate(ignoringOtherApps: true)
    }
}
