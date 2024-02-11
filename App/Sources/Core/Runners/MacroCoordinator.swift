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

  private(set) var newMacroKey: KeyShortcut?
  private(set) var recordingKey: MacroKey?

  private var currentBundleIdentifier: String = Bundle.main.bundleIdentifier!
  private var macros = [MacroKey: [MacroKind]]()

  private let bezelId = "com.apple.zenangst.Keyboard-Cowboy.macros"
  private let userSpace = UserSpace.shared

  func match(_ shortcut: KeyShortcut) -> [MacroKind]? {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                            machPortKeyId: shortcut.machPortKeyId)
    return macros[macroKey]
  }

  func record(_ shortcut: KeyShortcut,
              kind: MacroKind,
              machPortEvent: MachPortEvent) {
    if let recordingKey {
      if macros[recordingKey] == nil {
        macros[recordingKey] = [kind]
      } else {
        macros[recordingKey]?.append(kind)
      }
    } else {
      let recordingKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                                  machPortKeyId: shortcut.machPortKeyId)
      self.newMacroKey = shortcut
      macros[recordingKey] = nil
      self.recordingKey = recordingKey
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Recording Macro for \(shortcut.modifersDisplayValue) \(shortcut.key)"))
      }
      machPortEvent.result = nil
    }
  }

  func remove(_ shortcut: KeyShortcut, machPortEvent: MachPortEvent) {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                            machPortKeyId: shortcut.machPortKeyId)
    if macros[macroKey] != nil {
      macros[macroKey] = nil
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Removed Macro for \(shortcut.modifersDisplayValue) \(shortcut.key)"))
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

struct MacroRecordKey {
  let key: String
  let modifiers: [ModifierKey]

  func matches(_ shortcut: MachPortKeyboardShortcut) -> Bool {
    shortcut.original.key == key &&
    Set(shortcut.original.modifiers) == Set(modifiers)
  }
}

private extension KeyShortcut {
  var machPortKeyId: String {
    key + modifersDisplayValue + ":" + (lhs ? "true" : "false")
  }
}
