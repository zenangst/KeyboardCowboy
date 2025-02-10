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
  private let commandRunner: CommandRunner
  private let contentStore: ContentStore
  private let leaderKey: LeaderKeyCoordinator
  private let keyCodeStore: KeyCodesStore
  private let machPortCoordinator: MachPortCoordinator
  private let modifierTriggerController: ModifierTriggerController
  private let notificationCenterPublisher: NotificationCenterPublisher
  private let snippetController: SnippetController
  private let shortcutStore: ShortcutStore
  private let workspace: NSWorkspace
  private let workspacePublisher: WorkspacePublisher
  private let uiElementCaptureStore: UIElementCaptureStore
//  private let applicationWindowObserver: ApplicationWindowObserver

  private var pendingPermissionsSubscription: AnyCancellable?
  private var frontmostApplicationSubscription: AnyCancellable?
  private var machPortController: MachPortEventController?

  init(_ contentStore: ContentStore,
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       applicationTriggerController: ApplicationTriggerController,
//       applicationWindowObserver: ApplicationWindowObserver,
       commandRunner: CommandRunner,
       leaderKey: LeaderKeyCoordinator,
       keyboardCommandRunner: KeyboardCommandRunner,
       keyCodeStore: KeyCodesStore,
       machPortCoordinator: MachPortCoordinator,
       modifierTriggerController: ModifierTriggerController,
       notificationCenter: NotificationCenter = .default,
       scriptCommandRunner: ScriptCommandRunner,
       shortcutStore: ShortcutStore,
       snippetController: SnippetController,
       uiElementCaptureStore: UIElementCaptureStore,
       workspace: NSWorkspace = .shared) {
    self.applicationActivityMonitor = applicationActivityMonitor
    self.contentStore = contentStore
    self.leaderKey = leaderKey
    self.keyCodeStore = keyCodeStore
    self.commandRunner = commandRunner
    self.machPortCoordinator = machPortCoordinator
    self.modifierTriggerController = modifierTriggerController
    self.shortcutStore = shortcutStore
    self.uiElementCaptureStore = uiElementCaptureStore
    self.applicationTriggerController = applicationTriggerController
//    self.applicationWindowObserver = applicationWindowObserver
    self.snippetController = snippetController
    self.workspace = workspace
    self.workspacePublisher = WorkspacePublisher(workspace)
    self.notificationCenterPublisher = NotificationCenterPublisher(notificationCenter)

    guard KeyboardCowboyApp.env() != .previews else { return }

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
        onFlagsChanged: { [machPortCoordinator, modifierTriggerController, leaderKey] in
          if machPortCoordinator.mode == .intercept ||
             machPortCoordinator.mode == .recordMacro {
            modifierTriggerController.handleIfApplicable($0)
          }

          _ = leaderKey.handlePartialMatchIfApplicable(nil, machPortEvent: $0)
          machPortCoordinator.receiveFlagsChanged($0)
        },
        onEventChange: { [machPortCoordinator, modifierTriggerController, leaderKey] in
          if machPortCoordinator.mode == .intercept ||
             machPortCoordinator.mode == .recordMacro {
            modifierTriggerController.handleIfApplicable($0)
          }

          _ = leaderKey.handlePartialMatchIfApplicable(nil, machPortEvent: $0)

          if $0.event.type == .flagsChanged {
            if $0.isRepeat { return }
            machPortCoordinator.receiveFlagsChanged($0)
          } else {
            machPortCoordinator.receiveEvent($0)
          }
        })
      commandRunner.eventSource = newMachPortController.eventSource
      subscribe(to: workspace)
      contentStore.recorderStore.subscribe(to: machPortCoordinator.$recording)
      machPortCoordinator.subscribe(to: contentStore.recorderStore.$mode)
      machPortCoordinator.machPort = newMachPortController
      commandRunner.setMachPort(newMachPortController, coordinator: machPortCoordinator)
      machPortController = newMachPortController
      modifierTriggerController.machPort = newMachPortController
      keyCodeStore.subscribe(to: notificationCenterPublisher.$keyboardSelectionDidChange)
      uiElementCaptureStore.subscribe(to: machPortCoordinator)
      snippetController.subscribe(to: machPortCoordinator.$coordinatorEvent)
      SystemHideAllAppsRunner.machPort = newMachPortController
    } catch let error {
      NSAlert(error: error).runModal()
    }
  }

  // MARK: Private methods

  private func subscribe(to workspace: NSWorkspace) {
    WindowStore.shared.subscribe(to: UserSpace.shared.$frontmostApplication)

    snippetController.subscribe(to: contentStore.groupStore.$groups)

    guard KeyboardCowboyApp.env() == .production else { return }

    applicationTriggerController.subscribe(to: UserSpace.shared.$frontmostApplication)
    applicationTriggerController.subscribe(to: UserSpace.shared.$runningApplications)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
    modifierTriggerController.subscribe(to: contentStore.groupStore.$groups)
    applicationActivityMonitor.subscribe(to: UserSpace.shared.$frontmostApplication)

//    WindowSpace.shared.subscribe(to: UserSpace.shared.$frontmostApplication)
//    applicationWindowObserver.subscribe(to: UserSpace.shared.$frontmostApplication)
    SystemWindowTilingRunner.initialIndex()
  }
}
