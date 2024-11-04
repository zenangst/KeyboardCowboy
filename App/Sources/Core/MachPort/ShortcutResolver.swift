import Foundation
import Carbon
import Cocoa
import KeyCodes
import MachPort

enum KeyboardShortcutResult {
  case partialMatch(PartialMatch)
  case exact(Workflow)
}

protocol KeycodeLocating {
  func keyCode(for string: String, matchDisplayValue: Bool) -> Int?
}

protocol LookupToken {
  var lhs: Bool { get }
  var signature: CGEventSignature { get }
}

extension KeyCodesStore: KeycodeLocating { }

extension MachPortEvent: LookupToken {
  var signature: CGEventSignature { CGEventSignature.from(event) }
}

final class ShortcutResolver {
  private static let debug: Bool = false
  private var cache = [String: KeyboardShortcutResult]()

  let keyCodes: KeycodeLocating

  init(keyCodes: KeycodeLocating) {
    self.keyCodes = keyCodes
  }

  func lookup(_ token: LookupToken,
              bundleIdentifier: String,
              userModes: [UserMode] = [],
              partialMatch: PartialMatch = .init(rawValue: ".")) -> KeyboardShortcutResult? {
    let lhs = token.lhs
    let eventSignature = token.signature
    if !userModes.isEmpty {
      for userMode in userModes {
        let userModeKey = userMode.dictionaryKey(true)
        let scopedKeyWithUserMode = createKey(eventSignature: eventSignature, lhs: lhs,
                                              bundleIdentifier: bundleIdentifier,
                                              userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[scopedKeyWithUserMode] {
          if Self.debug { print("scopedKeyWithUserMode: \(scopedKeyWithUserMode)") }
          return result
        }

        let globalKeyWithUserMode = createKey(eventSignature: eventSignature, lhs: lhs,
                                              bundleIdentifier: "*", userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[globalKeyWithUserMode] {
          if Self.debug { print("globalKeyWithUserMode: \(globalKeyWithUserMode)") }

          return result
        }
      }
    }

    let scopedKey = createKey(eventSignature: eventSignature, lhs: lhs,
                              bundleIdentifier: bundleIdentifier, userModeKey: "", previousKey: partialMatch.rawValue)



    if let result = cache[scopedKey] {
      if Self.debug { print("scopeKey: \(scopedKey)") }
      return result
    }

    let globalKey = createKey(eventSignature: eventSignature, lhs: lhs,
                              bundleIdentifier: "*", userModeKey: "", previousKey: partialMatch.rawValue)

    if Self.debug { print("globalKey: \(globalKey)") }

    return cache[globalKey]
  }

  func allMatchingPrefix(_ prefix: String, shortcutIndexPrefix: Int) -> [Workflow] {
    var results = [KeyboardShortcutResult]()
    do {
      if let bundleIdentifier = NSWorkspace.shared.frontApplication?.bundleIdentifier {
        let lookup = "\(bundleIdentifier)\(prefix)"
        let keys = cache.keys.filter { $0.hasPrefix(lookup) }
        let matches = keys.compactMap { key in
          cache[key]
        }
        results.append(contentsOf: matches)
      }
    }

    do {
      let lookup = "*\(prefix)"
      let keys = cache.keys.filter { $0.hasPrefix(lookup) }
      let matches = keys.compactMap { key in
        cache[key]
      }
      results.append(contentsOf: matches)
    }

    var workflows = results.compactMap { result in
      switch result {
      case .partialMatch(let partialMatch):
        partialMatch.workflow
      case .exact(let workflow):
        workflow
      }
    }

    for (offset, workflow) in workflows.enumerated() {
      guard case .keyboardShortcuts(let trigger) = workflow.trigger else {
        continue
      }
      let shortcuts = Array(trigger.shortcuts.suffix(max(trigger.shortcuts.count - shortcutIndexPrefix, 0)))
      workflows[offset].trigger = .keyboardShortcuts(.init(
        shortcuts: shortcuts
      ))
    }

    return workflows
  }

  func cache(_ groups: [WorkflowGroup]) {
    var newCache = [String: KeyboardShortcutResult]()
    for group in groups {
      let bundleIdentifiers: [String]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      } else {
        bundleIdentifiers = ["*"]
      }

      bundleIdentifiers.forEach { bundleIdentifier in
        group.workflows.forEach { workflow in
          guard workflow.isEnabled else { return }
          guard case .keyboardShortcuts(let trigger) = workflow.trigger else { return }

          let count = trigger.shortcuts.count - 1
          var previousKey: String = "."
          var offset = 0
          trigger.shortcuts.forEach { keyboardShortcut in

            guard let keyCode = keyCodes.keyCode(for: keyboardShortcut.key, matchDisplayValue: true)
                             ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: true)
                             ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: false) else {
              return
            }

            var flags = keyboardShortcut.cgFlags

            if SpecialKeys.numericPadKeys.contains(keyCode) {
              flags.insert(.maskNumericPad)
            }

            if SpecialKeys.functionKeys.contains(keyCode) {
              flags.insert(.maskSecondaryFn)
            }

            let eventSignature = CGEventSignature(Int64(keyCode), flags)

            if Self.debug, workflow.name.contains("**") {
              print(workflow.name, eventSignature.id)
              print(keyCode, flags)
              print(".maskAlphaShift", flags.contains(.maskAlphaShift))
              print(".maskShift", flags.contains(.maskShift))
              print(".maskControl", flags.contains(.maskControl))
              print(".maskAlternate", flags.contains(.maskAlternate))
              print(".maskCommand", flags.contains(.maskCommand))
              print(".maskHelp", flags.contains(.maskHelp))
              print(".maskSecondaryFn", flags.contains(.maskSecondaryFn))
              print(".maskNumericPad", flags.contains(.maskNumericPad))
              print(".maskNonCoalesced", flags.contains(.maskNonCoalesced))
            }

            if group.userModes.isEmpty {
              let key = createKey(eventSignature: eventSignature,
                                  lhs: keyboardShortcut.lhs,
                                  bundleIdentifier: bundleIdentifier,
                                  userModeKey: "",
                                  previousKey: previousKey)
              previousKey += "\(eventSignature.dictionaryKey(keyboardShortcut.lhs))+"

              if offset == count {
                newCache[key] = .exact(workflow)
              } else {
                newCache[key] = .partialMatch(.init(rawValue: previousKey, workflow: workflow))
              }
            } else {
              // Only set the previous key once per iteration, otherwise
              // the depth will increase for each iteration over user modes.
              var didSetPreviousKey: Bool = false
              for userMode in group.userModes {
                let userModeKey = userMode.dictionaryKey(true)
                let key = createKey(eventSignature: eventSignature,
                                    lhs: keyboardShortcut.lhs,
                                    bundleIdentifier: bundleIdentifier,
                                    userModeKey: userModeKey,
                                    previousKey: previousKey)
                if !didSetPreviousKey {
                  previousKey += "\(eventSignature.dictionaryKey(keyboardShortcut.lhs))+"
                  didSetPreviousKey = true
                }

                if offset == count {
                  newCache[key] = .exact(workflow)
                } else {
                  newCache[key] = .partialMatch(.init(rawValue: previousKey, workflow: workflow))
                }
              }
            }

            offset += 1
          }
        }
      }
    }
    cache = newCache
  }

  // MARK: - Private methods

  private func createKey(eventSignature: CGEventSignature, lhs: Bool,
                         bundleIdentifier: String, userModeKey: String,
                         previousKey: String) -> String {
    "\(bundleIdentifier)\(previousKey)\(eventSignature.dictionaryKey(lhs))\(userModeKey)"
  }
}

private extension Array<UserMode> {
  func dictionaryKey(_ value: Bool) -> String {
    map { $0.dictionaryKey(value) }.joined()
  }
}

private extension UserMode {
  func dictionaryKey(_ value: Bool) -> String {
    return "\(prefix())\(value ? 1 : 0))"
  }

  private func prefix() -> String {
    return "UM:\(id):"
  }
}

private extension CGEventSignature {
  func dictionaryKey(_ lhs: Bool) -> String {
    return "[\(self.id):lhs:\(lhs)]"
  }
}

struct SpecialKeys {
  static let functionKeys: Set<Int> = [
    kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6,
    kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12,
    kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18,
    kVK_F19, kVK_F20,

    kVK_Home,
    kVK_End,
    kVK_PageUp,
    kVK_PageDown,

    kVK_UpArrow,
    kVK_DownArrow,
    kVK_LeftArrow,
    kVK_RightArrow,
    kVK_ANSI_KeypadEnter,
    kVK_JIS_KeypadComma,
  ]

  static let numericPadKeys: Set<Int> = [
    kVK_UpArrow,
    kVK_DownArrow,
    kVK_LeftArrow,
    kVK_RightArrow,
    kVK_ANSI_KeypadDecimal,
    kVK_ANSI_KeypadMultiply,
    kVK_ANSI_KeypadPlus,
    kVK_ANSI_KeypadClear,
    kVK_ANSI_KeypadDivide,
    kVK_ANSI_KeypadEnter,
    kVK_ANSI_KeypadMinus,
    kVK_ANSI_KeypadEquals,
    kVK_ANSI_Keypad0,
    kVK_ANSI_Keypad1,
    kVK_ANSI_Keypad2,
    kVK_ANSI_Keypad3,
    kVK_ANSI_Keypad4,
    kVK_ANSI_Keypad5,
    kVK_ANSI_Keypad6,
    kVK_ANSI_Keypad7,
    kVK_ANSI_Keypad8,
    kVK_ANSI_Keypad9,
    kVK_JIS_KeypadComma,
  ]
}
