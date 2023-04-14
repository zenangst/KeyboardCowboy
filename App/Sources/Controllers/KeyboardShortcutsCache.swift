import Foundation
import Cocoa

enum KeyboardShortcutResult {
  case partialMatch(String)
  case exact(Workflow)
}

final class KeyboardShortcutsCache {
  var cache = [String: KeyboardShortcutResult]()

  func lookup(_ keyboardShortcut: KeyShortcut, previousKey: String = ".") -> KeyboardShortcutResult? {
    if let bundleIdentifier = NSWorkspace.shared.frontApplication?.bundleIdentifier {
      let scopedKey = createKey(keyboardShortcut, bundleIdentifier: bundleIdentifier, previousKey: previousKey)
      if let result = cache[scopedKey] {
        return result
      }
    }
    let globalKey = createKey(keyboardShortcut, bundleIdentifier: "*", previousKey: previousKey)
    let result = cache[globalKey]
    return result
  }

  func createCache(_ groups: [WorkflowGroup]) {
    var newCache = [String: KeyboardShortcutResult]()
    for group in groups {
      var bundleIdentifiers: [String] = ["*"]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      }
      for bundleIdentifier in bundleIdentifiers {
        for workflow in group.workflows where workflow.isEnabled {
          guard case .keyboardShortcuts(let keyboardShortcuts) = workflow.trigger else { continue }

          let count = keyboardShortcuts.count - 1
          var previousKey: String = "."
          for (offset, keyboardShortcut) in keyboardShortcuts.enumerated() {
            let key = createKey(keyboardShortcut, bundleIdentifier: bundleIdentifier, previousKey: previousKey)
            previousKey += "\(keyboardShortcut.dictionaryKey)+"

            if offset == count {
              newCache[key] = .exact(workflow)
            } else {
              newCache[key] = .partialMatch(previousKey)
            }
          }
        }
      }
    }
    cache = newCache
  }

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
