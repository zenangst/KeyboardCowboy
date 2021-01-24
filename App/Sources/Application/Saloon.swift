import BridgeKit
import Combine
import Foundation
import LogicFramework
import ModelKit
import ViewKit
import SwiftUI
import Sparkle

/*
 This type alias exists soley to restore some order to all the chaos.
 The joke was simply too funny not to pass on, I apologize to future-self
 or any other poor soul that will get confused because of this reckless
 creative naming. Just know that at the time,
 it made me fill up with the giggles.

 Loads of love, zenangst <3
 */
typealias KeyboardCowboyStore = Saloon

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
let bundleIdentifier = Bundle.main.bundleIdentifier!

class Saloon: ViewKitStore, MenubarControllerDelegate {
  private static let factory = ControllerFactory()

  private let builtInController: BuiltInCommandController
  private let storageController: StorageControlling
  private let hudFeatureController = HUDFeatureController()
  private let pathFinderController = PathFinderController()

  private var coreController: CoreControlling?
  private var featureContext: FeatureContext?
  private var keyboardShortcutWindowController: NSWindowController?
  private var loaded: Bool = false
  private var menuBarController: MenubarController?
  private var quickRunFeatureController: QuickRunFeatureController?
  private var quickRunWindowController: NSWindowController?
  private var settingsController: SettingsController?
  private var subscriptions = Set<AnyCancellable>()

  @Environment(\.scenePhase) var scenePhase
  @Published var state: ApplicationState = .launching

  init() {
    Debug.isEnabled = launchArguments.isEnabled(.debug)
    let configuration = Configuration.Storage()
    self.storageController = Self.factory.storageController(
      path: configuration.path,
      fileName: configuration.fileName)
    self.builtInController = BuiltInCommandController()

    do {
      // Don't run the entire app when running tests
      if launchArguments.isEnabled(.runningUnitTests) ||
          isRunningPreview {
        super.init(groups: [], context: .preview())
        return
      }

      let installedApplications = Self.loadApplications()

      var groups = try storageController.load()
      groups = pathFinderController.patch(groups, applications: installedApplications)
      let groupsController = Self.factory.groupsController(groups: groups)
      let hotKeyController = try? Self.factory.hotkeyController()

      let coreController = Self.factory.coreController(
        launchArguments.isEnabled(.disableKeyboardShortcuts) ? .disabled : .enabled,
        bundleIdentifier: bundleIdentifier,
        builtInCommandController: builtInController,
        groupsController: groupsController,
        hotKeyController: hotKeyController,
        installedApplications: installedApplications
      )

      self.coreController = coreController

      let context = FeatureFactory(coreController: coreController).featureContext(
        keyInputSubjectWrapper: Self.keyInputSubject)
      let viewKitContext = context.viewKitContext(keyInputSubjectWrapper: Self.keyInputSubject)

      super.init(groups: groups, context: viewKitContext)

      self.quickRunFeatureController = QuickRunFeatureController(commandController: coreController.commandController)
      self.subscribe(to: context)
      self.context = viewKitContext
      self.featureContext = context
    } catch let error {
      AppDelegateErrorController.handle(error)
      super.init(groups: [], context: .preview())
    }
  }

  public func initialLoad() {
    guard !loaded else { return }

    settingsController = SettingsController(userDefaults: .standard)
    subscribe(to: UserDefaults.standard, context: context)
    subscribe(to: NotificationCenter.default)
    loaded = true

    SUUpdater.shared()?.checkForUpdatesInBackground()
    createKeyboardShortcutWindow()
    createQuickRun()
  }

  func receive(_ scenePhase: ScenePhase) {
    switch scenePhase {
    case .active:
      initialLoad()
    case .background, .inactive:
      break
    @unknown default:
      assertionFailure("Unknown scene phase: \(scenePhase)")
    }
  }

  static func applicationDirectories() -> [URL] {
    var urls = [URL]()
    if let userDirectory = try? FileManager.default.url(for: .applicationDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false) {
      urls.append(userDirectory)
    }
    if let applicationDirectory = try? FileManager.default.url(for: .allApplicationsDirectory,
                                                           in: .localDomainMask,
                                                           appropriateFor: nil,
                                                           create: false) {
      urls.append(applicationDirectory)
    }
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    let coreServicesDirectory = URL(fileURLWithPath: "/System/Library/CoreServices")
    let applicationDirectoryD = URL(fileURLWithPath: "/Developer/Applications")
    let applicationDirectoryN = URL(fileURLWithPath: "/Network/Applications")
    let applicationDirectoryND = URL(fileURLWithPath: "/Network/Developer/Applications")
    let applicationDirectoryS = URL(fileURLWithPath: "/Users/Shared/Applications")
    let systemApplicationsDirectory = URL(fileURLWithPath: "/System/Applications")

    urls.append(contentsOf: [homeDirectory, coreServicesDirectory,
                applicationDirectoryD, applicationDirectoryN,
                applicationDirectoryND, applicationDirectoryS,
                systemApplicationsDirectory])

    return urls
  }

  // MARK: Private methods

  private func createQuickRun() {
    guard let quickRunFeatureController = quickRunFeatureController else { return }

    let window = QuickRunWindow(contentRect: .init(origin: .zero, size: CGSize(width: 300, height: 500)))
    window.minSize.height = 530
    let windowController = QuickRunWindowController(window: window,
                                                    featureController: quickRunFeatureController)
    self.quickRunWindowController = windowController
    self.quickRunFeatureController?.window = window
    builtInController.windowController = windowController
  }

  private func createKeyboardShortcutWindow() {
    let window = FloatingWindow(contentRect: .init(origin: .zero, size: CGSize(width: 300, height: 200)))
    let windowController = NSWindowController(window: window)
    var hudStack = HUDStack(hudProvider: hudFeatureController.erase())
    hudStack.window = window
    windowController.contentViewController = NSHostingController(rootView: hudStack)
    windowController.window = window

    coreController?.publisher.sink(receiveValue: { newValue in
      self.hudFeatureController.state = newValue
    }).store(in: &subscriptions)

    windowController.showWindow(nil)
    window.setFrameOrigin(.zero)

    self.keyboardShortcutWindowController = windowController
  }

  private static func loadApplications() -> [Application] {
    let urls: [URL] = applicationDirectories()
    let fileIndexer = FileIndexController(urls: urls)
    var patterns = FileIndexPatternsFactory.patterns()
    patterns.append(contentsOf: FileIndexPatternsFactory.pathExtensions())
    patterns.append(contentsOf: FileIndexPatternsFactory.lastPathComponents())

    let applicationParser = ApplicationParser()

    return fileIndexer.index(with: patterns, match: {
      $0.absoluteString.contains(".app")
    }, handler: applicationParser.process(_:))
    .sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
  }

  private func subscribe(to context: FeatureContext) {
    context.groups.subject
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { groups in
        self.groups = groups

        self.quickRunFeatureController?.storage = self.groups.flatMap({ $0.workflows })

        if let selectedGroup = self.selectedGroup,
           let group =  groups.first(where: { $0.id == selectedGroup.id }) {
          self.context.workflows.perform(.set(group: group))
        }
      }.store(in: &subscriptions)

    context.groups.subject
      .debounce(for: 1.0, scheduler: RunLoop.current)
      .removeDuplicates()
      .receive(on: DispatchQueue.global(qos: .userInitiated))
      .sink { groups in
        self.saveGroupsToDisk(groups)
      }
      .store(in: &subscriptions)
  }

  private func subscribe(to userDefaults: UserDefaults,
                         context: ViewKitFeatureContext) {
    userDefaults.publisher(for: \.groupSelection).sink { newValue in
      guard let newValue = newValue else { return }
      if let newGroup = self.groups.first(where: { $0.id == newValue }) {
        self.selectedGroup = newGroup
        context.workflows.perform(.set(group: newGroup))
      }
    }.store(in: &subscriptions)

    userDefaults.publisher(for: \.workflowSelection).sink { newValue in
      guard let newValue = newValue else {
        self.selectedWorkflow = nil
        return
      }
      let selectedWorkflow = self.groups.flatMap({ $0.workflows }).first(where: { $0.id == newValue })
      if let selectedWorkflow = selectedWorkflow {
        context.workflow.perform(.set(workflow: selectedWorkflow))
      }
      self.selectedWorkflow = selectedWorkflow
    }.store(in: &subscriptions)

    userDefaults.publisher(for: \.hideMenuBarIcon).sink { newValue in
      if newValue {
        self.menuBarController = nil
        return
      }
      self.menuBarController = MenubarController()
      self.menuBarController?.delegate = self
    }.store(in: &subscriptions)
  }

  private func subscribe(to notificationCenter: NotificationCenter) {
    notificationCenter.publisher(for: HotKeyNotification.enableHotKeys.notification).sink { _ in
      if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
        self.coreController?.setState(.enabled)
      }
    }.store(in: &subscriptions)

    notificationCenter.publisher(for: HotKeyNotification.enableRecordingHotKeys.notification).sink { _ in
      self.coreController?.setState(.recording)
    }.store(in: &subscriptions)

    notificationCenter.publisher(for: HotKeyNotification.disableHotKeys.notification).sink { _ in
      if !launchArguments.isEnabled(.disableKeyboardShortcuts) {
        self.coreController?.setState(.disabled)
      }
    }.store(in: &subscriptions)

    var notificationsEnabled: Bool = launchArguments.isEnabled(.openWindowAtLaunch)

    notificationCenter.publisher(for: NSApplication.didBecomeActiveNotification)
      .sink { _ in
        if self.loaded && notificationsEnabled {
          self.openMainWindow()
        }
        notificationsEnabled = true
      }.store(in: &subscriptions)
  }

  private func saveGroupsToDisk(_ groups: [ModelKit.Group]) {
    do {
      try storageController.save(groups)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  private func openMainWindow() {
    let quickRunIsOpen = quickRunWindowController?.window?.isVisible == true

    if !quickRunIsOpen && (NSApp.mainWindow?.className.contains("AppWindow") == true ||
        NSApp.mainWindow == nil) {
      NSApp.mainWindow?.center()
      NSWorkspace.shared.open(Bundle.main.bundleURL)
      receive(.active)
      state = .content(MainView(store: self, groupController: context.groups))
    }
  }

  // MARK: MenubarControllerDelegate
  func menubarController(_ controller: MenubarController, didTapOpenApplication openApplicationMenuItem: NSMenuItem) {
    openMainWindow()
  }
}
