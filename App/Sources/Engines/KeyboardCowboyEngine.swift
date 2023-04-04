import Combine
import Cocoa
import CoreGraphics
import Foundation
import MachPort
import os

@MainActor
final class KeyboardCowboyEngine {
  private var subscriptions = Set<AnyCancellable>()

  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let contentStore: ContentStore
  private let commandEngine: CommandEngine
  private let machPortEngine: MachPortEngine
  private let shortcutStore: ShortcutStore

  private let applicationTriggerController: ApplicationTriggerController
  private var machPortController: MachPortEventController?
  private var token: Any?

  private var waitingForPrivileges: Bool = false

  init(_ contentStore: ContentStore,
       keyboardEngine: KeyboardEngine,
       keyboardShortcutsCache: KeyboardShortcutsCache,
       scriptEngine: ScriptEngine,
       shortcutStore: ShortcutStore,
       workspace: NSWorkspace = .shared) {
    
    let commandEngine = CommandEngine(workspace, scriptEngine: scriptEngine, keyboardEngine: keyboardEngine)
    self.contentStore = contentStore
    self.commandEngine = commandEngine
    self.machPortEngine = MachPortEngine(store: keyboardEngine.store,
                                         commandEngine: commandEngine,
                                         keyboardEngine: keyboardEngine,
                                         keyboardShortcutsCache: keyboardShortcutsCache,
                                         mode: .intercept)
    self.shortcutStore = shortcutStore
    self.applicationTriggerController = ApplicationTriggerController(commandEngine)

    subscribe(to: workspace)

    machPortEngine.subscribe(to: contentStore.recorderStore.$mode)

    contentStore.recorderStore.subscribe(to: machPortEngine.$recording)

    guard !isRunningPreview else { return }

    guard !launchArguments.isEnabled(.disableMachPorts) else { return }

    if hasPrivileges() {
      do {
        try setupMachPort()
      } catch let error {
        os_log(.error, "\(error.localizedDescription)")
      }
    } else {
      waitingForPrivileges = true
    }
  }

  func setupMachPort() throws {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }
    let machPortController = try MachPortEventController(
      .privateState,
      signature: "com.zenangst.Keyboard-Cowboy",
      autoStartMode: .commonModes)
    commandEngine.eventSource = machPortController.eventSource
    machPortEngine.subscribe(to: machPortController.$event)
    machPortEngine.machPort = machPortController
    commandEngine.machPort = machPortController
    self.machPortController = machPortController
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
    let privOptions = [trusted: true] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

    return accessEnabled
  }

  private func subscribe(to workspace: NSWorkspace) {
    workspace.publisher(for: \.frontmostApplication)
      .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] application in
        self?.reload(with: application)
      }
      .store(in: &subscriptions)

    guard KeyboardCowboy.env == .production else { return }

    applicationTriggerController.subscribe(to: workspace)
    applicationTriggerController.subscribe(to: contentStore.groupStore.$groups)
  }

  private func reload(with application: NSRunningApplication) {
    guard KeyboardCowboy.env == .production else { return }
    guard contentStore.preferences.hideFromDock else { return }
    let newPolicy: NSApplication.ActivationPolicy
    if application.bundleIdentifier == bundleIdentifier {
      newPolicy = .regular
    } else {
      newPolicy = .accessory
    }

    if waitingForPrivileges {
      do {
        try setupMachPort()
      } catch {
        Swift.print(error)
      }
    }

    _ = NSApplication.shared.setActivationPolicy(newPolicy)
  }
}
