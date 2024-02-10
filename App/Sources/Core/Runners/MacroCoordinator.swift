import Foundation
import MachPort

enum MacroKind {
  case event(_ machPortEvent: MachPortEvent)
  case workflow(_ workflow: Workflow)
}

final class MacroCoordinator {
  private var currentBundleIdentifier: String = Bundle.main.bundleIdentifier!
  private var macros = [MacroKey: [MacroKind]]()
  private var newMacroKey: MachPortKeyboardShortcut?
  private var recordingKey: MacroKey?

  private let bezelId = "com.apple.zenangst.Keyboard-Cowboy.macros"
  private let recordKey = MacroRecordKey(key: "r", modifiers: [.function, .command])
  private let userSpace = UserSpace.shared

  func matchesRecorderKey(_ shortcut: MachPortKeyboardShortcut, 
                          mode: inout KeyboardCowboyMode,
                          machPortEvent: MachPortEvent) -> Bool {
    guard recordKey.matches(shortcut) else { return false }

    if machPortEvent.type == .keyUp {
      let text: String
      if let newMacroKey {
        text = "Recorded Macro for \(newMacroKey.original.modifersDisplayValue) \(newMacroKey.uppercase.key)"
        self.recordingKey = nil
        self.newMacroKey = nil
        mode = .intercept
      } else {
        text = "Choose Macro key..."
        mode = .recordMacro
      }

      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: text))
      }
    }

    return true
  }

  func record(_ shortcut: MachPortKeyboardShortcut,
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
                                  machPortKeyId: shortcut.id)
      self.newMacroKey = shortcut
      macros[recordingKey] = nil
      self.recordingKey = recordingKey
      Task { @MainActor [bezelId] in
        BezelNotificationController.shared.post(.init(id: bezelId, text: "Recording Macro for \(shortcut.original.modifersDisplayValue) \(shortcut.uppercase.key)"))
      }
      machPortEvent.result = nil
    }
  }

  func matchesMacroKey(_ shortcut: MachPortKeyboardShortcut, machPortEvent: MachPortEvent) -> [MacroKind]? {
    let macroKey = MacroKey(bundleIdentifier: userSpace.frontMostApplication.bundleIdentifier,
                            machPortKeyId: shortcut.id)
    return macros[macroKey]
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
