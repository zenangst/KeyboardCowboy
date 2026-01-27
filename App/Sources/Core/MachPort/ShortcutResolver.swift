import Carbon
import Cocoa
import Foundation
import KeyCodes
import MachPort

enum KeyboardShortcutResult {
  case partialMatch(PartialMatch)
  case exact(Workflow)
}

@MainActor
protocol KeycodeLocating {
  @MainActor func specialKeys() -> [Int: String]
  @MainActor func keyCode(for string: String, matchDisplayValue: Bool) -> Int?
  @MainActor func displayValue(for keyCode: Int, modifiers: [VirtualModifierKey]) -> String?
}

protocol LookupToken {
  var keyCode: Int64 { get }
  var flags: CGEventFlags { get }
  var signature: CGEventSignature { get }
}

extension KeyCodesStore: KeycodeLocating {}

extension MachPortEvent: LookupToken {
  var flags: CGEventFlags { event.flags }
  var signature: CGEventSignature { CGEventSignature.from(event) }
}

@MainActor final class ShortcutResolver {
  enum Fallback {
    case functionKey
    case remainder(originalFlags: UInt64)
  }

  private static let debug: Bool = false
  private var cache = [String: KeyboardShortcutResult]()
  private var disallowedBundleIdentifiers = Set<String>()

  let keyCodes: KeycodeLocating

  init(keyCodes: KeycodeLocating) {
    self.keyCodes = keyCodes
  }

  func lookup(_ keyShortcut: KeyShortcut) -> Int? {
    keyCodes.keyCode(for: keyShortcut.key, matchDisplayValue: true)
  }

  func lookup(_ token: LookupToken,
              bundleIdentifier: String,
              userModes: [UserMode] = [],
              partialMatch: PartialMatch = .init(rawValue: "."),
              fallback: Fallback? = .functionKey) -> KeyboardShortcutResult? {
    let eventSignature = token.signature
    if !userModes.isEmpty {
      for userMode in userModes {
        let userModeKey = userMode.dictionaryKey(true)
        let scopedKeyWithUserMode = Self.createKey(eventSignature: eventSignature,
                                                   bundleIdentifier: bundleIdentifier,
                                                   userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[scopedKeyWithUserMode] {
          if Self.debug { print("scopedKeyWithUserMode: \(scopedKeyWithUserMode)") }

          Debugger.shared.log(.shortcutResolver, "Found scoped usermode key for \(eventSignature.id)")

          return result
        }

        let globalKeyWithUserMode = Self.createKey(eventSignature: eventSignature,
                                                   bundleIdentifier: "*",
                                                   userModeKey: userModeKey,
                                                   previousKey: partialMatch.rawValue)

        if let result = cache[globalKeyWithUserMode] {
          if Self.debug { print("globalKeyWithUserMode: \(globalKeyWithUserMode)") }

          Debugger.shared.log(.shortcutResolver, "Found global usermode key for \(eventSignature.id)")

          return result
        }
      }
    }

    let scopedKey = Self.createKey(eventSignature: eventSignature,
                                   bundleIdentifier: bundleIdentifier,
                                   userModeKey: "",
                                   previousKey: partialMatch.rawValue)

    if let result = cache[scopedKey] {
      if Self.debug { print("scopeKey: \(scopedKey)") }

      Debugger.shared.log(.shortcutResolver, "Found scoped key for \(eventSignature.id)")

      return result
    }

    let globalKey = Self.createKey(eventSignature: eventSignature,
                                   bundleIdentifier: "*", userModeKey: "", previousKey: partialMatch.rawValue)

    if Self.debug { print("globalKey: \(globalKey)") }

    if disallowedBundleIdentifiers.contains(scopedKey) {
      Debugger.shared.log(.shortcutResolver, "Skipping because scoped key is disallowed: \(scopedKey)")
      return nil
    }

    if let globalKeyResult = cache[globalKey] {
      Debugger.shared.log(.shortcutResolver, "Found global key for \(eventSignature.id)")
      return globalKeyResult
    } else if let fallback, SpecialKeys.functionKeys.contains(Int(token.keyCode)) {
      var newFlags = token.flags
      let newFallback: Fallback?
      switch fallback {
      case .functionKey:
        if newFlags.contains(.maskSecondaryFn) {
          newFlags.remove(.maskSecondaryFn)
        } else {
          newFlags.insert(.maskSecondaryFn)
        }
        newFallback = .remainder(originalFlags: token.flags.remainingFlags)
      case let .remainder(originalFlags):
        newFlags = CGEventFlags(rawValue: originalFlags)
        newFallback = nil
      }

      Debugger.shared.log(.shortcutResolver, "Trying fallback for \(eventSignature.id)")

      return lookup(
        FallbackLookupToken(keyCode: token.keyCode, flags: newFlags),
        bundleIdentifier: bundleIdentifier,
        fallback: newFallback,
      )
    } else {
      Debugger.shared.log(.shortcutResolver, "No match for \(eventSignature.id)")
      return nil
    }
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
      case let .partialMatch(partialMatch): partialMatch.workflow
      case let .exact(workflow): workflow
      }
    }

    for (offset, workflow) in workflows.enumerated() {
      guard case let .keyboardShortcuts(trigger) = workflow.trigger else {
        continue
      }

      let shortcuts = Array(trigger.shortcuts.suffix(max(trigger.shortcuts.count - shortcutIndexPrefix, 0)))
      workflows[offset].trigger = .keyboardShortcuts(.init(
        shortcuts: shortcuts,
      ))
    }

    return workflows
  }

  func cache(_ groups: [WorkflowGroup]) {
    var newCache = [String: KeyboardShortcutResult]()
    for group in groups where !group.isDisabled {
      let allowedBundleIdentifiers: [String]
      let disallowedBundleIdentifiers: [String]
      if let rule = group.rule {
        if !rule.allowedBundleIdentifiers.isEmpty {
          allowedBundleIdentifiers = rule.allowedBundleIdentifiers
        } else {
          allowedBundleIdentifiers = ["*"]
        }

        disallowedBundleIdentifiers = rule.disallowedBundleIdentifiers
      } else {
        allowedBundleIdentifiers = ["*"]
        disallowedBundleIdentifiers = []
      }

      for allowedBundleIdentifier in allowedBundleIdentifiers {
        for workflow in group.workflows where workflow.isEnabled {
          guard case let .keyboardShortcuts(trigger) = workflow.trigger else { continue }

          let count = trigger.shortcuts.count - 1
          var previousKey = "."
          var offset = 0
          for keyboardShortcut in trigger.shortcuts {
            guard let keyCode = keyCodes.keyCode(for: keyboardShortcut.key, matchDisplayValue: true)
              ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: true)
              ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: false)
              ?? resolveAnyKeyCode(keyboardShortcut)
            else {
              continue
            }

            var flags = keyboardShortcut.cgFlags

            if SpecialKeys.numericPadKeys.contains(keyCode) {
              flags.insert(.maskNumericPad)
            }

            if SpecialKeys.functionKeys.contains(keyCode) {
              flags.insert(.maskSecondaryFn)
            }

            let eventSignature = CGEventSignature(Int64(keyCode), flags)

            if group.userModes.isEmpty {
              let key = Self.createKey(eventSignature: eventSignature,
                                       bundleIdentifier: allowedBundleIdentifier,
                                       userModeKey: "",
                                       previousKey: previousKey)
              let currentPreviousKey = previousKey
              previousKey += "\(eventSignature.id)+"

              if offset == count {
                DynamicWorkspace.createDynamicWorkflows(
                  for: workflow,
                  keyCode: Int64(keyCode),
                  flags: flags,
                  bundleIdentifier: allowedBundleIdentifier,
                  userModeKey: "",
                  previousKey: currentPreviousKey,
                ) { newKey, match in
                  newCache[newKey] = match
                }
                newCache[key] = .exact(workflow)
              } else {
                if case let .partialMatch(match) = newCache[key],
                   let workflow = match.workflow, workflow.machPortConditions.isLeaderKey {
                } else {
                  newCache[key] = .partialMatch(.init(rawValue: previousKey, workflow: workflow))
                }
              }
            } else {
              // Only set the previous key once per iteration, otherwise
              // the depth will increase for each iteration over user modes.
              var didSetPreviousKey = false
              for userMode in group.userModes {
                let userModeKey = userMode.dictionaryKey(true)
                let currentPreviousKey = previousKey
                let key = Self.createKey(eventSignature: eventSignature,
                                         bundleIdentifier: allowedBundleIdentifier,
                                         userModeKey: userModeKey,
                                         previousKey: previousKey)
                if !didSetPreviousKey {
                  previousKey += "\(eventSignature.id)+"
                  didSetPreviousKey = true
                }

                let lastItem = offset == count

                if lastItem {
                  DynamicWorkspace.createDynamicWorkflows(
                    for: workflow,
                    keyCode: Int64(keyCode),
                    flags: flags,
                    bundleIdentifier: allowedBundleIdentifier,
                    userModeKey: userModeKey,
                    previousKey: currentPreviousKey,
                  ) { newKey, match in
                    newCache[newKey] = match
                  }
                  newCache[key] = .exact(workflow)
                } else {
                  if case let .partialMatch(match) = newCache[key],
                     let workflow = match.workflow, workflow.machPortConditions.isLeaderKey {
                  } else {
                    newCache[key] = .partialMatch(.init(rawValue: previousKey, workflow: workflow))
                  }
                }
              }
            }

            offset += 1
          }
        }
      }

      self.disallowedBundleIdentifiers = []
      for disallowedBundleIdentifier in disallowedBundleIdentifiers {
        for workflow in group.workflows where workflow.isEnabled {
          guard case let .keyboardShortcuts(trigger) = workflow.trigger else { continue }

          var previousKey = "."

          for keyboardShortcut in trigger.shortcuts {
            guard let keyCode = keyCodes.keyCode(for: keyboardShortcut.key, matchDisplayValue: true)
              ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: true)
              ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: false)
              ?? resolveAnyKeyCode(keyboardShortcut)
            else {
              continue
            }

            var flags = keyboardShortcut.cgFlags

            if SpecialKeys.numericPadKeys.contains(keyCode) {
              flags.insert(.maskNumericPad)
            }

            if SpecialKeys.functionKeys.contains(keyCode) {
              flags.insert(.maskSecondaryFn)
            }

            let eventSignature = CGEventSignature(Int64(keyCode), flags)
            let key = Self.createKey(eventSignature: eventSignature,
                                     bundleIdentifier: disallowedBundleIdentifier,
                                     userModeKey: "",
                                     previousKey: previousKey)
            if !self.disallowedBundleIdentifiers.contains(key) {
              self.disallowedBundleIdentifiers.insert(key)
            }
            previousKey += "\(eventSignature.id)+"
          }
        }
      }
    }
    cache = newCache
  }

  // MARK: - Static methods

  static func createKey(eventSignature: CGEventSignature,
                        bundleIdentifier: String, userModeKey: String,
                        previousKey: String) -> String {
    "\(bundleIdentifier)\(previousKey)\(eventSignature.id)\(userModeKey)"
  }

  // MARK: - Private methods

  private func resolveAnyKeyCode(_ keyShortcut: KeyShortcut) -> Int? {
    keyShortcut.key == KeyShortcut.anyKey.key
      ? KeyShortcut.anyKeyCode
      : nil
  }
}

private struct FallbackLookupToken: LookupToken {
  var signature: CGEventSignature { CGEventSignature(keyCode, flags) }

  let keyCode: Int64
  let flags: CGEventFlags
}
