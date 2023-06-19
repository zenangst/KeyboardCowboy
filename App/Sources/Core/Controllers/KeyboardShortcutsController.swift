import Foundation
import Cocoa

enum KeyboardShortcutResult {
  case partialMatch(PartialMatch)
  case exact(Workflow)
}

struct PartialMatch {
  let rawValue: String
}

final class KeyboardShortcutsController {
  private var cache = [String: KeyboardShortcutResult]()

  func lookup(_ keyboardShortcut: KeyShortcut, partialMatch: PartialMatch = .init(rawValue: ".")) -> KeyboardShortcutResult? {
    if let bundleIdentifier = NSWorkspace.shared.frontApplication?.bundleIdentifier {
      let scopedKey = createKey(keyboardShortcut, bundleIdentifier: bundleIdentifier, previousKey: partialMatch.rawValue)
      if let result = cache[scopedKey] {
        return result
      }
    }
    let globalKey = createKey(keyboardShortcut, bundleIdentifier: "*", previousKey: partialMatch.rawValue)
    let result = cache[globalKey]
    return result
  }

  func cache(_ groups: [WorkflowGroup]) {
    var newCache = [String: KeyboardShortcutResult]()
    groups.forEach { group in
      var bundleIdentifiers: [String] = ["*"]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      }
      bundleIdentifiers.forEach { bundleIdentifier in
        group.workflows.forEach { workflow in
          guard workflow.isEnabled else { return }
          guard case .keyboardShortcuts(let trigger) = workflow.trigger else { return }

          let count = trigger.shortcuts.count - 1
          var previousKey: String = "."
          var offset = 0
          trigger.shortcuts.forEach { keyboardShortcut in
            let key = createKey(keyboardShortcut, bundleIdentifier: bundleIdentifier, previousKey: previousKey)
            previousKey += "\(keyboardShortcut.dictionaryKey)+"

            if offset == count {
              newCache[key] = .exact(workflow)
            } else {
              newCache[key] = .partialMatch(.init(rawValue: previousKey))
            }

            offset += 1
          }
        }
      }
    }
    cache = newCache
  }

  // MARK: - Private methods

  private func createKey(_ keyboardShortcut: KeyShortcut, bundleIdentifier: String, previousKey: String) -> String {
    "\(bundleIdentifier)\(previousKey)\(keyboardShortcut.dictionaryKey)"
  }
}

private extension KeyShortcut {
  var dictionaryKey: String {
    if modifersDisplayValue.isEmpty {
      return "[\(key):\(lhs)]"
    } else {
      return "[\(modifersDisplayValue)+\(key):\(lhs)]"
    }
  }
}
