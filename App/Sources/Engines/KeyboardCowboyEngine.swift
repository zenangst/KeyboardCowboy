import Combine
import Cocoa
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

  private var machPortController: MachPortEventController?

  init(_ contentStore: ContentStore, indexer: Indexer,
       scriptEngine: ScriptEngine, workspace: NSWorkspace = .shared) {
    let keyCodeStore = KeyCodesStore()
    let commandEngine = CommandEngine(workspace,
                                      scriptEngine: scriptEngine,
                                      keyCodeStore: keyCodeStore)
    self.contentStore = contentStore
    self.commandEngine = commandEngine
    self.machPortEngine = MachPortEngine(store: keyCodeStore, commandEngine: commandEngine,
                                         indexer: indexer, mode: .intercept)
    self.shortcutStore = ShortcutStore(engine: scriptEngine)

    subscribe(to: workspace)

    machPortEngine.subscribe(to: contentStore.recorderStore.$mode)

    contentStore.recorderStore.subscribe(to: machPortEngine.$recording)

    guard !isRunningPreview else { return }

    guard contentStore.preferences.machportIsEnabled else { return }

    if !hasPrivileges() { } else {
      do {
        if !launchArguments.isEnabled(.runningUnitTests) {
          let machPortController = try MachPortEventController(
            .privateState,
            signature: "com.zenangst.Keyboard-Cowboy",
            mode: .commonModes)
          commandEngine.eventSource = machPortController.eventSource
          machPortEngine.subscribe(to: machPortController.$event)
          machPortEngine.machPort = machPortController
          commandEngine.machPort = machPortController
          self.machPortController = machPortController
        }
      } catch let error {
        os_log(.error, "\(error.localizedDescription)")
      }
    }

  }

  func run(_ commands: [Command], serial: Bool) {
    if serial {
      commandEngine.serialRun(commands)
    } else {
      commandEngine.concurrentRun(commands)
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
      .compactMap { $0 }
      .sink { [weak self] application in
        self?.reload(with: application)
      }
      .store(in: &subscriptions)
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

    _ = NSApplication.shared.setActivationPolicy(newPolicy)
  }
}
