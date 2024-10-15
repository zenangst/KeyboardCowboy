import Foundation
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
  private var cache = [String: KeyboardShortcutResult]()

  let keyCodes: KeycodeLocating

  init(keyCodes: KeycodeLocating) {
    self.keyCodes = keyCodes
  }

  func lookup(_ token: LookupToken,
              bundleIdentifier: String,
              userModes: [UserMode],
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
          return result
        }

        let globalKeyWithUserMode = createKey(eventSignature: eventSignature, lhs: lhs,
                                              bundleIdentifier: "*", userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[globalKeyWithUserMode] {
          return result
        }
      }
    }

    let scopedKey = createKey(eventSignature: eventSignature, lhs: lhs,
                              bundleIdentifier: bundleIdentifier, userModeKey: "", previousKey: partialMatch.rawValue)

    if let result = cache[scopedKey] {
      return result
    }

    let globalKey = createKey(eventSignature: eventSignature, lhs: lhs,
                              bundleIdentifier: "*", userModeKey: "", previousKey: partialMatch.rawValue)

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
            let arrows = 123...126
            if arrows.contains(keyCode) {
              flags.insert(.maskNumericPad)
            }

            let eventSignature = CGEventSignature(keyCode, flags)

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

