import Foundation
import MachPort

enum MacroKind {
  case event(_ machPortEvent: MachPortEvent)
  case workflow(_ workflow: Workflow)
}

final class MacroCoordinator {
  enum State {
    case recording
    case removing
    case idle
  }

  var state: State = .idle {
    willSet {
      if newValue == .idle {
        newMacroKey = nil
        recordingKey = nil
      }
    }
  }
  var machPort: MachPortEventController?

  private(set) var newMacroKey: MachPortKeyboardShortcut?
  private(set) var recordingKey: MacroKey?

  private var currentBundleIdentifier: String = Bundle.main.bundleIdentifier!
  private var macros = [MacroKey: [MacroKind]]()

  private let bezelId = "com.apple.zenangst.Keyboard-Cowboy.macros"

  @MainActor
  private let userSpace: UserSpace

  @MainActor
  init() {
    self.userSpace = UserSpace.shared
  }

  func match(_ shortcut: MachPortKeyboardShortcut) -> [MacroKind]? {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                            machPortKeyId: shortcut.id)
    if let macro = macros[macroKey] {
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Running Macro for \(shortcut.original.modifersDisplayValue) \(shortcut.uppercase.key)"))
      }
      return macro
    }

    return nil
  }

  func record(_ shortcut: MachPortKeyboardShortcut, kind: MacroKind, machPortEvent: MachPortEvent) {
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
      if shortcut.id == newMacroKey.id {
        machPortEvent.result = nil
        state = .idle
        Task { @MainActor [bezelId] in
          BezelNotificationController.shared.post(.init(id: bezelId, text: "Recorded Macro for \(shortcut.original.modifersDisplayValue) \(shortcut.uppercase.key)"))
        }
        return
      }

      if macros[recordingKey] == nil {
        macros[recordingKey] = [kind]
      } else {
        macros[recordingKey]?.append(kind)
      }
    } else {
      let recordingKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                                  machPortKeyId: shortcut.id)
      macros[recordingKey] = nil
      self.newMacroKey = shortcut
      self.recordingKey = recordingKey
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Recording Macro for \(shortcut.original.modifersDisplayValue) \(shortcut.uppercase.key)"))
      }
      machPortEvent.result = nil
    }
  }

  func remove(_ shortcut: MachPortKeyboardShortcut, machPortEvent: MachPortEvent) {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                            machPortKeyId: shortcut.id)
    if macros[macroKey] != nil {
      macros[macroKey] = nil
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Removed Macro for \(shortcut.original.modifersDisplayValue) \(shortcut.uppercase.key)"))
      }
    }

    state = .idle
    machPortEvent.result = nil
  }
}

struct MacroKey: Hashable {
  let bundleIdentifier: String
  let machPortKeyId: String
}

private extension KeyShortcut {
  var machPortKeyId: String {
    key + modifersDisplayValue + ":" + (lhs ? "true" : "false")
  }
}
