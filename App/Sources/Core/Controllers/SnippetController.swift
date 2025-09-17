import Carbon
import Cocoa
import Combine
import Foundation
import KeyCodes
import MachPort

final class SnippetController: @unchecked Sendable, ObservableObject {
  var isEnabled: Bool = true

  @MainActor
  static var currentSnippet: String = ""

  @MainActor
  private var currentSnippet: String = ""
  private var machPortEventSubscription: AnyCancellable?
  private var snippetsStorage = [String: [Workflow]]()
  private var workflowGroupsSubscription: AnyCancellable?
  private var runningTask: Task<Void, any Error>?

  private let commandRunner: CommandRunning
  private let customCharSet: CharacterSet
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let specialKeys: [Int]
  private let store: KeyCodesStore

  init(commandRunner: CommandRunning,
       keyboardCommandRunner: KeyboardCommandRunner,
       store: KeyCodesStore)
  {
    self.commandRunner = commandRunner
    self.keyboardCommandRunner = keyboardCommandRunner
    self.store = store
    specialKeys = Array(store.specialKeys().keys)

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
    guard isEnabled else {
      return
    }

    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let forbiddenKeys = [kVK_Escape, kVK_Space, kVK_Tab, kVK_Delete, kVK_ForwardDelete]

    if forbiddenKeys.contains(keyCode) {
      currentSnippet = ""
      runningTask?.cancel()
      return
    }

    guard !snippetsStorage.isEmpty, event.type == .keyDown else { return }

    let modifiers = VirtualModifierKey.modifiers(for: keyCode, flags: event.flags, specialKeys: Array(store.specialKeys().keys))

    guard let displayValue = store.displayValue(for: keyCode, modifiers: modifiers) else {
      return
    }

    currentSnippet = currentSnippet + displayValue
    Self.currentSnippet = currentSnippet

    guard let runningApplication = NSWorkspace.shared.frontmostApplication,
          let bundleIdentifier = runningApplication.bundleIdentifier else { return }

    let globalKey = "*." + currentSnippet
    let localKey: String = bundleIdentifier + "." + currentSnippet

    guard let workflows = snippetsStorage[localKey] ?? snippetsStorage[globalKey],
          let machPortEvent = MachPortEvent.empty()
    else {
      return
    }

    runningTask?.cancel()
    let runningTask = Task { @MainActor in
      // Clean up snippet before running command
      if let key = VirtualSpecialKey.keys[kVK_Delete] {
        for _ in 0 ..< currentSnippet.count {
          _ = try? await keyboardCommandRunner.run([.init(key: key)], iterations: 1, with: nil)
        }
      }

      for workflow in workflows {
        let task = commandRunner.serialRun(
          workflow.commands,
          checkCancellation: true,
          resolveUserEnvironment: true,
          machPortEvent: machPortEvent,
          repeatingEvent: false
        )

        try await task.value

        if Task.isCancelled {
          task.cancel()
          throw CancellationError()
        }
      }

      self.currentSnippet = ""
      self.runningTask = nil
    }
    self.runningTask = runningTask
  }

  private func receiveGroups(_ groups: [WorkflowGroup]) {
    snippetsStorage = [:]

    for group in groups {
      let bundleIdentifiers: [String]
      if let rule = group.rule {
        bundleIdentifiers = rule.allowedBundleIdentifiers
      } else {
        bundleIdentifiers = ["*"]
      }

      for bundleIdentifier in bundleIdentifiers {
        for workflow in group.workflows {
          guard workflow.isEnabled else { continue }

          if let trigger = workflow.trigger {
            switch trigger {
            case let .snippet(trigger):
              guard !workflow.commands.isEmpty else { continue }
              guard !trigger.text.isEmpty else { continue }

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

extension CGEvent: @unchecked @retroactive Sendable { }
