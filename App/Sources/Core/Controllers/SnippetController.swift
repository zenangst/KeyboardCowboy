import Carbon
import Combine
import Foundation
import KeyCodes
import MachPort

final class SnippetController: @unchecked Sendable, ObservableObject {
  var isEnabled: Bool = true

  private var currentSnippet: String = ""
  private var machPortEventSubscription: AnyCancellable?
  private var snippets: Set<String> = []
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
      .sink { [weak self] machPortEvent in
      self?.receiveCGEvent(machPortEvent)
    }
  }

  // MARK: Private methods

  private func receiveCGEvent(_ event: CGEvent) {
    guard isEnabled && !snippets.isEmpty, event.type == .keyDown else { return }
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

    currentSnippet = currentSnippet + displayValue

    timeout?.invalidate()
    timeout = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { [weak self] timer in
      guard let self else { return }
      currentSnippet = ""
      timer.invalidate()
    })

    if snippets.contains(currentSnippet) {
      guard let workflows = snippetsStorage[currentSnippet],
            let machPortEvent = MachPortEvent.empty() else { return }

      // Clean up snippet before running command
      if let key = VirtualSpecialKey.keys[kVK_Delete] {
        for _ in 0..<currentSnippet.count {
            _ = try? keyboardCommandRunner.run([.init(key: key)], type: .keyDown, with: nil)
            _ = try? keyboardCommandRunner.run([.init(key: key)], type: .keyUp, with: nil)
        }
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
    self.snippets = []

    let workflows = groups.flatMap { $0.workflows }

    for workflow in workflows {
      guard workflow.isEnabled else { continue }
        if let trigger = workflow.trigger {
            switch trigger {
            case .snippet(let trigger):
              guard !trigger.text.isEmpty else { return }

              if let existingWorkflows = snippetsStorage[trigger.text] {
                snippetsStorage[trigger.text] = existingWorkflows + [workflow]
              } else {
                snippetsStorage[trigger.text] = [workflow]
              }

              snippets.insert(trigger.text)
            default: break
            }
        } else {
            runCommands(in: workflow)
        }
    }
  }

  private func runCommands(in workflow: Workflow) {
    let commands = workflow.commands.filter(\.isEnabled)
    guard let machPortEvent = MachPortEvent.empty() else { return }
    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    case .serial:
      commandRunner.serialRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    }
  }
}
