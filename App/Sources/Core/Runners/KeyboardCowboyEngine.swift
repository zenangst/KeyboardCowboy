import AXEssibility
import Combine
import Cocoa
import CoreGraphics
import Foundation
import MachPort
import os

@MainActor
final class KeyboardCowboyEngine {
  private let applicationTriggerController: ApplicationTriggerController
  private let applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>
  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let commandRunner: CommandRunner
  private let contentStore: ContentStore
  private let keyCodeStore: KeyCodesStore
  private let machPortCoordinator: MachPortCoordinator
  private let notificationCenterPublisher: NotificationCenterPublisher
  private let snippetController: SnippetController
  private let shortcutStore: ShortcutStore
  private let workspace: NSWorkspace
  private let workspacePublisher: WorkspacePublisher
  private let uiElementCaptureStore: UIElementCaptureStore
  private let workflowRunner: WorkflowRunning
  private let applicationWindowObserver: ApplicationWindowObserver

  private var pendingPermissionsSubscription: AnyCancellable?
  private var frontmostApplicationSubscription: AnyCancellable?
  private var machPortController: MachPortEventController?

  init(_ contentStore: ContentStore,
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       applicationTriggerController: ApplicationTriggerController,
       applicationWindowObserver: ApplicationWindowObserver,
       commandRunner: CommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner,
       keyboardShortcutsController: KeyboardShortcutsController,
       keyCodeStore: KeyCodesStore,
       machPortCoordinator: MachPortCoordinator,
       notificationCenter: NotificationCenter = .default,
       scriptCommandRunner: ScriptCommandRunner,
       shortcutStore: ShortcutStore,
       snippetController: SnippetController,
       uiElementCaptureStore: UIElementCaptureStore,
       workflowRunner: WorkflowRunning,
       workspace: NSWorkspace = .shared) {
    self.applicationActivityMonitor = applicationActivityMonitor
    self.contentStore = contentStore
    self.keyCodeStore = keyCodeStore
    self.commandRunner = commandRunner
    self.machPortCoordinator = machPortCoordinator
    self.shortcutStore = shortcutStore
    self.uiElementCaptureStore = uiElementCaptureStore
    self.applicationTriggerController = applicationTriggerController
    self.applicationWindowObserver = applicationWindowObserver
    self.snippetController = snippetController
    self.workspace = workspace
    self.workflowRunner = workflowRunner
    self.workspacePublisher = WorkspacePublisher(workspace)
    self.notificationCenterPublisher = NotificationCenterPublisher(notificationCenter)

    guard KeyboardCowboy.env() != .previews else { return }

    commandRunner.runners.application.delegate = applicationTriggerController

    guard !launchArguments.isEnabled(.disableMachPorts) else { return }

    if AccessibilityPermission.shared.permission != .authorized {
      AccessibilityPermission.shared.subscribe(to: NSWorkspace.shared.publisher(for: \.frontmostApplication)) { [weak self] in
        self?.setupMachPortAndSubscriptions(workspace)
      }
    } else {
      setupMachPortAndSubscriptions(workspace)
    }
  }

  func setupMachPortAndSubscriptions(_ workspace: NSWorkspace) {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }

    do {
      let keyboardEvents: CGEventMask = (1 << CGEventType.keyDown.rawValue)
                                      | (1 << CGEventType.keyUp.rawValue)
                                      | (1 << CGEventType.flagsChanged.rawValue)

      let newMachPortController = try MachPortEventController(
        .privateState,
        eventsOfInterest: keyboardEvents,
        signature: "com.zenangst.Keyboard-Cowboy",
        autoStartMode: .commonModes,
        onFlagsChanged: { [machPortCoordinator] in machPortCoordinator.receiveFlagsChanged($0) },
        onEventChange: { [machPortCoordinator] in machPortCoordinator.receiveEvent($0) })
      commandRunner.eventSource = newMachPortController.eventSource
      subscribe(to: workspace)
      contentStore.recorderStore.subscribe(to: machPortCoordinator.$recording)
      machPortCoordinator.subscribe(to: contentStore.recorderStore.$mode)
      machPortCoordinator.machPort = newMachPortController
      commandRunner.setMachPort(newMachPortController, coordinator: machPortCoordinator)
      machPortController = newMachPortController
      keyCodeStore.subscribe(to: notificationCenterPublisher.$keyboardSelectionDidChange)
      uiElementCaptureStore.subscribe(to: machPortCoordinator)
      snippetController.subscribe(to: machPortCoordinator.$coordinatorEvent)
    } catch let error {
      NSAlert(error: error).runModal()
    }
  }

  // MARK: Private methods

  private func subscribe(to workspace: NSWorkspace) {
    WindowStore.shared.subscribe(to: UserSpace.shared.$frontMostApplication)

    snippetController.subscribe(to: contentStore.groupStore.$groups)

    guard KeyboardCowboy.env() == .production else { return }

    applicationTriggerController.subscribe(to: UserSpace.shared.$frontMostApplication)
    applicationTriggerController.subscribe(to: UserSpace.shared.$runningApplications)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
    applicationActivityMonitor.subscribe(to: UserSpace.shared.$frontMostApplication)
    applicationWindowObserver.subscribe(to: UserSpace.shared.$frontMostApplication)
    SystemWindowTilingRunner.initialIndex()
  }
}
