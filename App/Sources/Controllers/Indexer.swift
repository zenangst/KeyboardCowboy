import Foundation
import Cocoa

enum IndexType {
  case single(Workflow)
  case sequence([Workflow])
}

final class Indexer {
  var cache = [String: IndexType]()

  func validate(_ event: MachPortEngine.Event) -> IndexType? {
    if let bundleIdentifier = NSWorkspace.shared.frontApplication?.bundleIdentifier,
       let match = cache[event.keyboardShortcut.dictionaryKey(bundleIdentifier)] {
      return match
    }

    if let match = cache[event.keyboardShortcut.dictionaryKey("*")] {
      return match
    }

    return nil 
  }

  func run(_ groups: [WorkflowGroup]) {
    var newCache = [String: IndexType]()

    for group in groups {
      var bundleIdentifiers: [String] = ["*"]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      }

      for workflow in group.workflows where workflow.isEnabled {
        guard case .keyboardShortcuts(let keyboardShortcuts) = workflow.trigger else {
          continue
        }

        let singleKey = keyboardShortcuts.count == 1
        for keyboardShortcut in keyboardShortcuts {
          for bundleId in bundleIdentifiers {
            let dictKey = keyboardShortcut.dictionaryKey(bundleId)

            if singleKey {
              newCache[dictKey] = .single(workflow)
            } else if let currentEntry = newCache[bundleId] {
              switch currentEntry {
              case .single(let entry):
                newCache[dictKey] = .sequence([entry, workflow])
              case .sequence(var workflows):
                workflows.append(workflow)
                newCache[dictKey] = .sequence(workflows)
              }
            } else {
              newCache[dictKey] = .sequence([workflow])
            }
          }
        }
      }
    }

    cache = newCache
  }
}

private extension KeyShortcut {
  func dictionaryKey(_ bundleIdentifier: String) -> String {
      return "\(bundleIdentifier).\(key)-\(modifersDisplayValue)-\(lhs)"
  }
}
