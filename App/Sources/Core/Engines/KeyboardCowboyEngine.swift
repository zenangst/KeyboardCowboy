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
  private let commandEngine: CommandEngine
  private let contentStore: ContentStore
  private let keyCodeStore: KeyCodesStore
  private let machPortEngine: MachPortEngine
  private let notificationCenterPublisher: NotificationCenterPublisher
  private let shortcutStore: ShortcutStore
  private let workspace: NSWorkspace
  private let workspacePublisher: WorkspacePublisher

  private var frontmostApplicationSubscription: AnyCancellable?
  private var machPortController: MachPortEventController?
  private var waitingForPrivileges: Bool = false

  init(_ contentStore: ContentStore,
       keyboardEngine: KeyboardEngine,
       keyboardShortcutsController: KeyboardShortcutsController,
       keyCodeStore: KeyCodesStore,
       notificationCenter: NotificationCenter = .default,
       scriptEngine: ScriptEngine,
       shortcutStore: ShortcutStore,
       workspace: NSWorkspace = .shared) {
    
    let commandEngine = CommandEngine(workspace, scriptEngine: scriptEngine, keyboardEngine: keyboardEngine)
    self.contentStore = contentStore
    self.keyCodeStore = keyCodeStore
    self.commandEngine = commandEngine
    self.machPortEngine = MachPortEngine(store: keyboardEngine.store,
                                         commandEngine: commandEngine,
                                         keyboardEngine: keyboardEngine,
                                         keyboardShortcutsController: keyboardShortcutsController,
                                         mode: .intercept)
    self.shortcutStore = shortcutStore
    self.applicationTriggerController = ApplicationTriggerController(commandEngine)
    self.workspace = workspace
    self.workspacePublisher = WorkspacePublisher(workspace)
    self.notificationCenterPublisher = NotificationCenterPublisher(notificationCenter)

    guard KeyboardCowboy.env != .designTime else { return }

    guard !launchArguments.isEnabled(.disableMachPorts) else { return }

    if hasPrivileges() {
      do {
        try setupMachPortAndSubscriptions(workspace)
      } catch let error {
        // TODO: Improve error handling here
        NSAlert(error: error).runModal()
      }
    } else {
      waitingForPrivileges = true
    }
  }

  func setupMachPortAndSubscriptions(_ workspace: NSWorkspace) throws {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }

    let newMachPortController = try MachPortEventController(
      .privateState,
      signature: "com.zenangst.Keyboard-Cowboy",
      autoStartMode: .commonModes)
    commandEngine.eventSource = newMachPortController.eventSource
    subscribe(to: workspace)
    contentStore.recorderStore.subscribe(to: machPortEngine.$recording)
    machPortEngine.subscribe(to: contentStore.recorderStore.$mode)
    machPortEngine.subscribe(to: newMachPortController.$event)
    machPortEngine.machPort = newMachPortController
    commandEngine.machPort = newMachPortController
    machPortController = newMachPortController
    keyCodeStore.subscribe(to: notificationCenterPublisher.$keyboardSelectionDidChange)
  }

  func run(_ commands: [Command], execution: Workflow.Execution) {
    switch execution {
    case .concurrent:
      commandEngine.concurrentRun(commands)
    case .serial:
      commandEngine.serialRun(commands)
    }
  }

  func reveal(_ commands: [Command]) {
    commandEngine.reveal(commands)
  }

  // MARK: Private methods

  private func hasPrivileges() -> Bool {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: false] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

    return accessEnabled
  }

  private func subscribe(to workspace: NSWorkspace) {
    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] application in
        self?.reload(with: application)
      }

    guard KeyboardCowboy.env == .production else { return }

    applicationTriggerController.subscribe(to: workspacePublisher.$frontmostApplication)
    applicationTriggerController.subscribe(to: workspacePublisher.$runningApplications)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
  }

  private func reload(with application: NSRunningApplication) {
    guard KeyboardCowboy.env == .production else { return }

    if contentStore.preferences.hideFromDock {
      let newPolicy: NSApplication.ActivationPolicy
      if application.bundleIdentifier == bundleIdentifier {
        newPolicy = .regular
      } else {
        newPolicy = .accessory
      }
      _ = NSApplication.shared.setActivationPolicy(newPolicy)
    }

    if waitingForPrivileges {
      do {
        try setupMachPortAndSubscriptions(workspace)
      } catch {
        Swift.print(error)
      }
    }
  }
}
