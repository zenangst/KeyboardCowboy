import AXEssibility
import Cocoa
import Combine
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
  private let tapHeld: TapHeldCoordinator
  private let keyCodeStore: KeyCodesStore
  private let machPortCoordinator: MachPortCoordinator
  private let modifierTriggerController: ModifierTriggerController
  private let notificationCenterPublisher: NotificationCenterPublisher
  private let snippetController: SnippetController
  private let shortcutStore: ShortcutStore
  private let workspace: NSWorkspace
  private let workspacePublisher: WorkspacePublisher
  private let uiElementCaptureStore: UIElementCaptureStore
  private let applicationWindowObserver: ApplicationWindowObserver

  private var pendingPermissionsSubscription: AnyCancellable?
  private var frontmostApplicationSubscription: AnyCancellable?
  private var machPortController: MachPortEventController?

  init(_ contentStore: ContentStore,
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       applicationTriggerController: ApplicationTriggerController,
       applicationWindowObserver: ApplicationWindowObserver,
       commandRunner: CommandRunner,
       keyCodeStore: KeyCodesStore,
       keyboardCommandRunner _: KeyboardCommandRunner,
       machPortCoordinator: MachPortCoordinator,
       modifierTriggerController: ModifierTriggerController,
       notificationCenter: NotificationCenter = .default,
       scriptCommandRunner _: ScriptCommandRunner,
       shortcutStore: ShortcutStore,
       snippetController: SnippetController,
       tapHeld: TapHeldCoordinator,
       uiElementCaptureStore: UIElementCaptureStore,
       workspace: NSWorkspace = .shared) {
    self.applicationActivityMonitor = applicationActivityMonitor
    self.applicationTriggerController = applicationTriggerController
    self.applicationWindowObserver = applicationWindowObserver
    self.commandRunner = commandRunner
    self.contentStore = contentStore
    self.keyCodeStore = keyCodeStore
    self.machPortCoordinator = machPortCoordinator
    self.modifierTriggerController = modifierTriggerController
    notificationCenterPublisher = NotificationCenterPublisher(notificationCenter)
    self.shortcutStore = shortcutStore
    self.snippetController = snippetController
    self.tapHeld = tapHeld
    self.uiElementCaptureStore = uiElementCaptureStore
    self.workspace = workspace
    workspacePublisher = WorkspacePublisher(workspace)

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
      let keyCache = KeyPressCache()
      let newMachPortController = try MachPortEventController(
        .privateState,
        eventsOfInterest: keyboardEvents,
        signature: "com.zenangst.Keyboard-Cowboy",
        autoStartMode: .commonModes,
        onFlagsChanged: { [machPortCoordinator, tapHeld, modifierTriggerController] in
          let allowsEscapeFallback: Bool = !modifierTriggerController.handleIfApplicable($0)
          _ = tapHeld.handlePartialMatchIfApplicable(nil, machPortEvent: $0)
          machPortCoordinator.receiveFlagsChanged($0, allowsEscapeFallback: allowsEscapeFallback)
          keyCache.handle($0.event)
        },
        onEventChange: { [machPortCoordinator, tapHeld, modifierTriggerController] in
          let allowsEscapeFallback: Bool = !modifierTriggerController.handleIfApplicable($0)
          _ = tapHeld.handlePartialMatchIfApplicable(nil, machPortEvent: $0)

          if $0.event.type == .flagsChanged {
            if $0.isRepeat { return }
            machPortCoordinator.receiveFlagsChanged($0, allowsEscapeFallback: allowsEscapeFallback)
          } else {
            machPortCoordinator.receiveEvent($0)
          }

          keyCache.handle($0.event)

          if !$0.isRepeat, keyCache.noKeysPressed() {
            tapHeld.reset()
          }
        },
      )
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
    } catch {
      NSAlert(error: error).runModal()
    }
  }

  // MARK: Private methods

  private func subscribe(to _: NSWorkspace) {
    WindowStore.shared.subscribe(to: UserSpace.shared.$frontmostApplication)

    snippetController.subscribe(to: contentStore.groupStore.$groups)

    guard KeyboardCowboyApp.env() == .production else { return }

    applicationTriggerController.subscribe(to: UserSpace.shared.$frontmostApplication)
    applicationTriggerController.subscribe(to: UserSpace.shared.$runningApplications)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
    modifierTriggerController.subscribe(to: contentStore.groupStore.$groups)
    applicationActivityMonitor.subscribe(to: UserSpace.shared.$frontmostApplication)

//    WindowSpace.shared.subscribe(to: UserSpace.shared.$frontmostApplication)
    applicationWindowObserver.subscribe(to: UserSpace.shared.$frontmostApplication)
    WindowTilingRunner.index()

    applicationWindowObserver.frontMostApplicationDidCreateWindow = {
      WindowStore.shared.index()
    }

    applicationWindowObserver.frontMostApplicationDidCloseWindow = {
      WindowStore.shared.index()
    }
  }
}
