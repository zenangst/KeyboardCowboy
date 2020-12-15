import BridgeKit
import Combine
import Foundation
import LogicFramework
import ModelKit
import ViewKit
import SwiftUI

/*
 This type alias exists soley to restore some order to all the chaos.
 The joke was simply too funny not to pass on, I apologize to future-self
 or any other poor soul that will get confused because of this reckless
 creative naming. Just know that at the time,
 it made me fill up with the giggles.

 Loads of love, zenangst <3
 */
typealias KeyboardCowboyStore = Saloon

let bundleIdentifier = Bundle.main.bundleIdentifier!

class Saloon: ViewKitStore, MenubarControllerDelegate {
  enum ApplicationState {
    case launching(LaunchView)
    case needsPermission(PermissionsView)
    case content(MainView)

    var currentView: AnyView {
      switch self {
      case .launching(let view):
        return view.erase()
      case .needsPermission(let view):
        return view.erase()
      case .content(let view):
        return view.erase()
      }
    }
  }

  private static let factory = ControllerFactory()

  private let storageController: StorageControlling

  private var featureContext: FeatureContext?
  private var coreController: CoreControlling?
  private var settingsController: SettingsController?
  private var menuBarController: MenubarController?
  private var subscriptions = Set<AnyCancellable>()
  private var loaded: Bool = false

  @Published var state: ApplicationState = .launching(LaunchView())

  init() {
    let configuration = Configuration.Storage()
    self.storageController = Self.factory.storageController(
      path: configuration.path,
      fileName: configuration.fileName)
    do {
      let groups = try storageController.load()
      let groupsController = Self.factory.groupsController(groups: groups)
      let coreController = Self.factory.coreController(
        launchArguments.isEnabled(.disableKeyboardShortcuts) ? .disabled : .enabled,
        groupsController: groupsController)

      self.coreController = coreController

      let context = FeatureFactory(coreController: coreController).featureContext(
        keyInputSubjectWrapper: Self.keyInputSubject)
      let viewKitContext = context.viewKitContext(keyInputSubjectWrapper: Self.keyInputSubject)

      super.init(groups: groups, context: viewKitContext)

      self.subscribe(to: context)
      self.context = viewKitContext
      self.featureContext = context
      self.state = .content(MainView(store: self, groupController: viewKitContext.groups))
    } catch let error {
      AppDelegateErrorController.handle(error)
      super.init(groups: [], context: nil)
    }
  }

  public func initialLoad() {
    guard !loaded else { return }

    settingsController = SettingsController(userDefaults: .standard)
    subscribe(to: UserDefaults.standard, context: context)
    subscribe(to: NotificationCenter.default)
    loaded = true
  }

  func receive(_ scenePhase: ScenePhase) {
    switch scenePhase {
    case .active:
      initialLoad()
      if UserDefaults.standard.hideDockIcon {
        NSApp.setActivationPolicy(.regular)
      }
    case .background:
      if UserDefaults.standard.hideDockIcon {
        NSApp.setActivationPolicy(.accessory)
      }
    case .inactive:
      break
    @unknown default:
      assertionFailure("Unknown scene phase: \(scenePhase)")
    }
  }

  // MARK: Private methods

  private func subscribe(to context: FeatureContext) {
    context.groups.subject
      .receive(on: DispatchQueue.main)
      .sink { groups in
        self.groups = groups
      }.store(in: &subscriptions)

    context.groups.subject
      .debounce(for: 0.5, scheduler: RunLoop.main)
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
      self.selectedGroup = self.groups.first(where: { $0.id == newValue })
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
  }

  private func saveGroupsToDisk(_ groups: [ModelKit.Group]) {
    do {
      try storageController.save(groups)
    } catch let error {
      AppDelegateErrorController.handle(error)
    }
  }

  // MARK: MenubarControllerDelegate
  func menubarController(_ controller: MenubarController, didTapOpenApplication openApplicationMenuItem: NSMenuItem) {
    receive(.active)
    NSWorkspace.shared.open(Bundle.main.bundleURL)
  }
}
