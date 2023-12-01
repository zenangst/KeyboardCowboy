import Foundation
import Cocoa

enum KeyboardShortcutResult {
  case partialMatch(PartialMatch)
  case exact(Workflow)
}

struct PartialMatch {
  let rawValue: String
  let workflow: Workflow?

  init(rawValue: String, workflow: Workflow? = nil) {
    self.rawValue = rawValue
    self.workflow = workflow
  }
}

final class KeyboardShortcutsController {
  private var cache = [String: KeyboardShortcutResult]()

  func lookup(_ keyboardShortcut: KeyShortcut, 
              bundleIdentifier: String,
              userModes: [UserMode],
              partialMatch: PartialMatch = .init(rawValue: ".")) -> KeyboardShortcutResult? {
    let userModeKey = userModes.filter({ $0.isEnabled == true }).dictionaryKey(true)
    let scopedKeyWithUserMode = createKey(
      keyboardShortcut,
      bundleIdentifier: bundleIdentifier,
      userModeKey: userModeKey,
      previousKey: partialMatch.rawValue
    )

    if let result = cache[scopedKeyWithUserMode] { return result }

    let scopedKey = createKey(
      keyboardShortcut,
      bundleIdentifier: bundleIdentifier,
      userModeKey: "",
      previousKey: partialMatch.rawValue
    )

    if let result = cache[scopedKey] { return result }

    let globalKeyWithUserMode = createKey(
      keyboardShortcut,
      bundleIdentifier: "*",
      userModeKey: userModeKey,
      previousKey: partialMatch.rawValue
    )


    if let result = cache[globalKeyWithUserMode] { return result }

    let globalKey = createKey(
      keyboardShortcut,
      bundleIdentifier: "*",
      userModeKey: "",
      previousKey: partialMatch.rawValue
    )

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
      let shortcuts = Array(trigger.shortcuts.suffix(shortcutIndexPrefix))
      workflows[offset].trigger = .keyboardShortcuts(.init(
        shortcuts: shortcuts
      ))
    }

    return workflows
  }

  func cache(_ groups: [WorkflowGroup]) async {
    await Benchmark.shared.start("KeyboardShortcutsController.cache")

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
            let userModeKey = group.userModes.dictionaryKey(true)
            let key = createKey(keyboardShortcut,
                                bundleIdentifier: bundleIdentifier,
                                userModeKey: userModeKey,
                                previousKey: previousKey)
            previousKey += "\(keyboardShortcut.dictionaryKey())+"

            if offset == count {
              newCache[key] = .exact(workflow)
            } else {
              newCache[key] = .partialMatch(.init(rawValue: previousKey, workflow: workflow))
            }

            offset += 1
          }
        }
      }
    }
    cache = newCache
    await Benchmark.shared.finish("KeyboardShortcutsController.cache")
  }

  // MARK: - Private methods

  private func createKey(
    _ keyboardShortcut: KeyShortcut,
    bundleIdentifier: String,
    userModeKey: String,
    previousKey: String
  ) -> String {
    "\(bundleIdentifier)\(previousKey)\(keyboardShortcut.dictionaryKey())\(userModeKey)"
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

private extension KeyShortcut {
  func dictionaryKey() -> String {
    if modifersDisplayValue.isEmpty {
      return "[\(key):\(lhs)]"
    } else {
      return "[\(modifersDisplayValue)+\(key):\(lhs)]"
    }
  }
}
