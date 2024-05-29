import Carbon
import Cocoa
import Combine
import Foundation
import KeyCodes
import MachPort

final class SnippetController: @unchecked Sendable, ObservableObject {
  var isEnabled: Bool = true

  static var currentSnippet: String = ""

  @MainActor
  private var currentSnippet: String = ""
  private var machPortEventSubscription: AnyCancellable?
  private var snippetsStorage = [String: [Workflow]]()
  private var timeout: Timer?
  private var workflowGroupsSubscription: AnyCancellable?

  private let commandRunner: CommandRunning
  private let customCharSet: CharacterSet
  private let keyboardShortcutsController: KeyboardShortcutsController
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let specialKeys: [Int]
  private let store: KeyCodesStore

  init(commandRunner: CommandRunning,
       keyboardCommandRunner: KeyboardCommandRunner,
       keyboardShortcutsController: KeyboardShortcutsController,
       store: KeyCodesStore) {
    self.commandRunner = commandRunner
    self.keyboardCommandRunner = keyboardCommandRunner
    self.keyboardShortcutsController = keyboardShortcutsController
    self.store = store
    self.specialKeys = Array(store.specialKeys().keys)

    var customCharSet = CharacterSet.alphanumerics
    customCharSet.insert(charactersIn: "ÉéÅåÄäÖöÆæØøÜü")
    self.customCharSet = customCharSet
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] in
      self?.receiveGroups($0)
    }
  }

  func subscribe(to publisher: Published<CGEvent?>.Publisher) {
    machPortEventSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] cgEvent in
        guard let self else { return }
        Task { [cgEvent] in
          await self.receiveCGEvent(cgEvent)
        }
    }
  }

  // MARK: Private methods

  @MainActor
  private func receiveCGEvent(_ event: CGEvent) {
    guard isEnabled && !snippetsStorage.isEmpty, event.type == .keyDown else { return }
    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let forbiddenKeys = [kVK_Escape, kVK_Space, kVK_Delete]

    if forbiddenKeys.contains(keyCode) {
      currentSnippet = ""
      timeout?.invalidate()
      return
    }

    let modifiers = VirtualModifierKey.fromCGEvent(event, specialKeys: specialKeys)

    // Figure out which modifier to apply to get the correct display value.
    var modifier: VirtualModifierKey?
    if modifiers == [.shift] {
      modifier = .shift
    } else if modifiers == [.option] {
      modifier = .option
    } else if modifiers == [.control] {
      modifier = .control
    }

    guard let displayValue = store.displayValue(for: keyCode, modifier: modifier) else {
      return
    }

    if displayValue == "." {
      currentSnippet = ""
      timeout?.invalidate()
      return
    }

    currentSnippet = currentSnippet + displayValue
    Self.currentSnippet = currentSnippet

    timeout?.invalidate()
    timeout = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
      guard let self else { return }
      Task { @MainActor in
        self.currentSnippet = ""
      }
      timer.invalidate()
    })

    guard let runningApplication = NSWorkspace.shared.frontmostApplication,
          let bundleIdentifier = runningApplication.bundleIdentifier else { return }

    let globalKey: String = "*." + currentSnippet
    let localKey: String = bundleIdentifier + "." + currentSnippet

    guard let workflows = snippetsStorage[localKey] ?? snippetsStorage[globalKey],
          let machPortEvent = MachPortEvent.empty() else {
      return
    }

    Task { @MainActor in
      // Clean up snippet before running command
      if let key = VirtualSpecialKey.keys[kVK_Delete] {
        for _ in 0..<currentSnippet.count {
          _ = try? keyboardCommandRunner.run([.init(key: key)], with: nil)
        }
        try await Task.sleep(for: .milliseconds(10))
      }

      for workflow in workflows {
        commandRunner.serialRun(
          workflow.commands,
          checkCancellation: false,
          resolveUserEnvironment: true,
          shortcut: .empty(),
          machPortEvent: machPortEvent,
          repeatingEvent: false
        )
      }

      currentSnippet = ""
      timeout?.invalidate()
    }
  }

  private func receiveGroups(_ groups: [WorkflowGroup]) {
    self.snippetsStorage = [:]

    for group in groups {
      let bundleIdentifiers: [String]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      } else {
        bundleIdentifiers = ["*"]
      }

      bundleIdentifiers.forEach { bundleIdentifier in
        for workflow in group.workflows {
          guard workflow.isEnabled else { continue }
          if let trigger = workflow.trigger {
            switch trigger {
            case .snippet(let trigger):
              guard !workflow.commands.isEmpty else { continue }
              guard !trigger.text.isEmpty else { return }

              let key = bundleIdentifier + "." + trigger.text

              if let existingWorkflows = snippetsStorage[trigger.text] {
                snippetsStorage[key] = existingWorkflows + [workflow]
              } else {
                snippetsStorage[key] = [workflow]
              }
            default: break
            }
          }
        }
      }
    }
  }
}

extension CGEvent: @unchecked Sendable {}
