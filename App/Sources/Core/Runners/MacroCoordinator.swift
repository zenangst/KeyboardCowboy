import Carbon
import Foundation
import KeyCodes
import MachPort

enum MacroKind {
  case event(_ machPortEvent: MachPortEvent)
  case workflow(_ workflow: Workflow)
}

final class MacroCoordinator: @unchecked Sendable {
  enum State {
    case recording
    case removing
    case idle
    case running
  }

  var state: State = .idle {
    willSet {
      if newValue == .idle {
        newMacroKey = nil
        recordingKey = nil
        recordingEvent = nil
      }
    }
  }
  var machPort: MachPortEventController?
  var keyCodes: KeyCodesStore

  private(set) var newMacroKey: MacroKey?
  private(set) var recordingKey: MacroKey?
  private(set) var recordingEvent: MachPortEvent?

  private var currentBundleIdentifier: String = Bundle.main.bundleIdentifier!
  private var macros = [MacroKey: [MacroKind]]()
  private var task: Task<Void, any Error>?

  private let bezelId = "com.apple.zenangst.Keyboard-Cowboy.macros"

  @MainActor
  private let userSpace: UserSpace

  @MainActor
  init(keyCodes: KeyCodesStore) {
    self.keyCodes = keyCodes
    self.userSpace = UserSpace.shared
  }

  func cancel() {
    task?.cancel()
  }

  func match(_ machPortEvent: MachPortEvent) -> [MacroKind]? {
    let eventSignature = CGEventSignature.from(machPortEvent.event)
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontmostApplication.bundleIdentifier, eventSignature: eventSignature)
    if let macro = macros[macroKey] {
      if let keyShortcut = keyShortcut(for: machPortEvent) {
        Task { @MainActor [bezelId] in
          BezelNotificationController.shared.post(.init(id: bezelId, text: "Running Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"))
        }
      }
      return macro
    }

    return nil
  }

  @MainActor
  func handleMacroExecution(_ machPortEvent: MachPortEvent,
                            machPort: MachPortEventController?,
                            keyboardRunner: KeyboardCommandRunner,
                            workflowRunner: WorkflowRunner,
                            eventSignature: CGEventSignature) -> Bool {
    cancel()

    if state == .idle, let macro = match(machPortEvent) {
      let currentSnippet = Int(SnippetController.currentSnippet) ?? 1
      let iterations = min(max(currentSnippet, 1), 10)

      state = .running

      task = Task.detached { [machPort, workflowRunner, keyboardRunner, weak self] in
        do {
          for _  in 0..<iterations {
            let specialKeys: [Int] = [kVK_Return, kVK_Escape]

            for element in macro {
              try Task.checkCancellation()
              switch element {
              case .event(let machPortEvent):
                let keyCode = Int(machPortEvent.keyCode)

                if specialKeys.contains(keyCode) { try await Task.sleep(for: .milliseconds(25)) }

                try machPort?.post(keyCode, type: .keyDown, flags: machPortEvent.event.flags)
                try machPort?.post(keyCode, type: .keyUp, flags: machPortEvent.event.flags)
                try await Task.sleep(for: .milliseconds(5))
              case .workflow(let workflow):
                if workflow.commands.allSatisfy({ $0.isKeyboardBinding }) {
                  for command in workflow.commands {
                    try Task.checkCancellation()
                    if case .keyboard(let command) = command {
                      _ = try await keyboardRunner.run(command.keyboardShortcuts,
                                                       originalEvent: nil,
                                                       iterations: command.iterations,
                                                       isRepeating: false,
                                                       with: machPortEvent.eventSource)
                      try await Task.sleep(for: .milliseconds(5))
                    }
                  }
                } else {
                  await workflowRunner.run(workflow, executionOverride: .serial, machPortEvent: machPortEvent, repeatingEvent: false)
                  try await Task.sleep(for: .milliseconds(5))
                }
              }
            }
          }
          await MainActor.run { [weak self] in
            self?.state = .idle
          }
        } catch {
          await MainActor.run { [weak self] in
            self?.state = .idle
          }
        }
      }

      SnippetController.currentSnippet = ""
      machPortEvent.result = nil
      return true
    } else if state == .removing {
      remove(eventSignature, machPortEvent: machPortEvent)
      machPortEvent.result = nil
      return true
    } else {
      return false
    }
  }

  func record(_ eventSignature: CGEventSignature, kind: MacroKind, machPortEvent: MachPortEvent) {
    guard state == .recording else { return }
    if case .workflow(let workflow) = kind {
      // Should never record macro related commands.
      let isValid = workflow.commands.contains(where: {
        switch $0 {
        case .builtIn(let command):
          switch command.kind {
          case .macro: false
          default: true
          }
        default:
          true
        }
      })

      if !isValid { return }
    }

    if let recordingKey, let newMacroKey {
      if eventSignature == newMacroKey.eventSignature {
        machPortEvent.result = nil
        state = .idle
        guard let recordingEvent, let keyShortcut = keyShortcut(for: recordingEvent) else { return }
        Task { @MainActor [bezelId] in
          BezelNotificationController.shared.post(.init(id: bezelId, text: "Recorded Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"))
        }
        return
      }

      if macros[recordingKey] == nil {
        macros[recordingKey] = [kind]
      } else {
        macros[recordingKey]?.append(kind)
      }
    } else {
      let bundleIdentifier = userSpace.frontmostApplication.bundleIdentifier
      let recordingKey = MacroKey(bundleIdentifier: bundleIdentifier, eventSignature: eventSignature)

      macros[recordingKey] = nil

      self.newMacroKey = recordingKey
      self.recordingKey = recordingKey
      self.recordingEvent = machPortEvent

      if let keyShortcut = keyShortcut(for: machPortEvent) {
        Task { @MainActor [bezelId] in
          BezelNotificationController.shared.post(.init(id: bezelId, text: "Recording Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"))
        }
      }
      machPortEvent.result = nil
    }
  }

  func remove(_ eventSignature: CGEventSignature, machPortEvent: MachPortEvent) {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontmostApplication.bundleIdentifier,
                            eventSignature: eventSignature)
    if macros[macroKey] != nil {
      macros[macroKey] = nil
      guard let keyShortcut = keyShortcut(for: machPortEvent) else { return }
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Removed Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"))
      }
    }

    state = .idle
    machPortEvent.result = nil
  }

  func keyShortcut(for machPortEvent: MachPortEvent) -> KeyShortcut? {
    if let key = keyCodes.displayValue(for: Int(machPortEvent.event.getIntegerValueField(.keyboardEventKeycode))) {
      let signature = CGEventSignature.from(machPortEvent.event)
      let keyShortcut = KeyShortcut(id: signature.id, key: key, modifiers: machPortEvent.event.modifierKeys)
      return keyShortcut
    }

    return nil
  }
}

struct MacroKey: Hashable {
  let bundleIdentifier: String
  let eventSignature: CGEventSignature
}
