import Combine
import Cocoa
import CoreGraphics
import Foundation
import MachPort
import os

@MainActor
final class KeyboardCowboyEngine {
  private let applicationTriggerController: ApplicationTriggerController
  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let commandRunner: CommandRunner
  private let contentStore: ContentStore
  private let keyCodeStore: KeyCodesStore
  private let machPortCoordinator: MachPortCoordinator
  private let notificationCenterPublisher: NotificationCenterPublisher
  private let shortcutStore: ShortcutStore
  private let workspace: NSWorkspace
  private let workspacePublisher: WorkspacePublisher

  private var pendingPermissionsSubscription: AnyCancellable?
  private var frontmostApplicationSubscription: AnyCancellable?
  private var machPortController: MachPortEventController?

  init(_ contentStore: ContentStore,
       commandRunner: CommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner,
       keyboardShortcutsController: KeyboardShortcutsController,
       keyCodeStore: KeyCodesStore,
       notificationCenter: NotificationCenter = .default,
       scriptCommandRunner: ScriptCommandRunner,
       shortcutStore: ShortcutStore,
       workspace: NSWorkspace = .shared) {
    
    self.contentStore = contentStore
    self.keyCodeStore = keyCodeStore
    self.commandRunner = commandRunner
    self.machPortCoordinator = MachPortCoordinator(store: keyboardCommandRunner.store,
                                                   commandRunner: commandRunner,
                                                   keyboardCommandRunner: keyboardCommandRunner,
                                                   keyboardShortcutsController: keyboardShortcutsController,
                                                   mode: .intercept)
    self.shortcutStore = shortcutStore
    self.applicationTriggerController = ApplicationTriggerController(commandRunner)
    self.workspace = workspace
    self.workspacePublisher = WorkspacePublisher(workspace)
    self.notificationCenterPublisher = NotificationCenterPublisher(notificationCenter)

    guard KeyboardCowboy.env() != .previews else { return }

    guard !launchArguments.isEnabled(.disableMachPorts) else { return }

    if AccessibilityPermission.shared.permission != .authorized {
      AccessibilityPermission.shared.subscribe(to: workspacePublisher.$frontmostApplication) { [weak self] in
        self?.setupMachPortAndSubscriptions(workspace)
      }
    } else {
      setupMachPortAndSubscriptions(workspace)
    }
  }

  func setupMachPortAndSubscriptions(_ workspace: NSWorkspace) {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }

    do {
      let newMachPortController = try MachPortEventController(
        .privateState,
        signature: "com.zenangst.Keyboard-Cowboy",
        autoStartMode: .commonModes)
      commandRunner.eventSource = newMachPortController.eventSource
      subscribe(to: workspace)
      contentStore.recorderStore.subscribe(to: machPortCoordinator.$recording)
      machPortCoordinator.subscribe(to: contentStore.recorderStore.$mode)
      machPortCoordinator.subscribe(to: newMachPortController.$event)
      machPortCoordinator.subscribe(to: newMachPortController.$flagsChanged)
      machPortCoordinator.machPort = newMachPortController
      commandRunner.setMachPort(newMachPortController)
      machPortController = newMachPortController
      keyCodeStore.subscribe(to: notificationCenterPublisher.$keyboardSelectionDidChange)
    } catch let error {
      NSAlert(error: error).runModal()
    }
  }

  func run(_ commands: [Command], execution: Workflow.Execution) {
    switch execution {
    case .concurrent:
      commandRunner.concurrentRun(commands)
    case .serial:
      commandRunner.serialRun(commands)
    }
  }

  func reveal(_ commands: [Command]) {
    commandRunner.reveal(commands)
  }

  // MARK: Private methods

  private func subscribe(to workspace: NSWorkspace) {
    frontmostApplicationSubscription = UserSpace.shared.$frontMostApplication
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] application in
        self?.reload(with: application)
      }

    guard KeyboardCowboy.env() == .production else { return }

    applicationTriggerController.subscribe(to: UserSpace.shared.$frontMostApplication)
    applicationTriggerController.subscribe(to: UserSpace.shared.$runningApplications)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
    WindowStore.shared.subscribe(to: UserSpace.shared.$frontMostApplication)
  }

  private func reload(with application: UserSpace.Application) {
    guard KeyboardCowboy.env() == .production else { return }

    if contentStore.preferences.hideFromDock {
      let newPolicy: NSApplication.ActivationPolicy
      if application.bundleIdentifier == bundleIdentifier {
        newPolicy = .regular
      } else {
        newPolicy = .accessory
      }
      _ = NSApplication.shared.setActivationPolicy(newPolicy)
    }
  }
}
