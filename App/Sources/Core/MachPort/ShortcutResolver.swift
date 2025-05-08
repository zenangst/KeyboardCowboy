import Foundation
import Carbon
import Cocoa
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

extension KeyCodesStore: KeycodeLocating { }

extension MachPortEvent: LookupToken {
  var flags: CGEventFlags { event.flags }
  var signature: CGEventSignature { CGEventSignature.from(event) }
}

@MainActor
final class ShortcutResolver {
  enum Fallback {
    case functionKey
    case remainder(originalFlags: UInt64)
  }
  private static let debug: Bool = false
  private var cache = [String: KeyboardShortcutResult]()

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
        let scopedKeyWithUserMode = createKey(eventSignature: eventSignature,
                                              bundleIdentifier: bundleIdentifier,
                                              userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[scopedKeyWithUserMode] {
          if Self.debug { print("scopedKeyWithUserMode: \(scopedKeyWithUserMode)") }
          return result
        }

        let globalKeyWithUserMode = createKey(eventSignature: eventSignature,
                                              bundleIdentifier: "*", userModeKey: userModeKey, previousKey: partialMatch.rawValue)

        if let result = cache[globalKeyWithUserMode] {
          if Self.debug { print("globalKeyWithUserMode: \(globalKeyWithUserMode)") }

          return result
        }
      }
    }

    let scopedKey = createKey(eventSignature: eventSignature,
                              bundleIdentifier: bundleIdentifier, userModeKey: "", previousKey: partialMatch.rawValue)



    if let result = cache[scopedKey] {
      if Self.debug { print("scopeKey: \(scopedKey)") }
      return result
    }

    let globalKey = createKey(eventSignature: eventSignature,
                              bundleIdentifier: "*", userModeKey: "", previousKey: partialMatch.rawValue)

    if Self.debug { print("globalKey: \(globalKey)") }

    if let globalKeyResult = cache[globalKey] {
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
      case .remainder(let originalFlags):
        newFlags = CGEventFlags(rawValue: originalFlags)
        newFallback = nil
      }

      return lookup(
        FallbackLookupToken(keyCode: token.keyCode, flags: newFlags),
        bundleIdentifier: bundleIdentifier,
        fallback: newFallback
      )
    } else {
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
    for group in groups where !group.isDisabled {
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
                   ?? keyCodes.keyCode(for: keyboardShortcut.key.lowercased(), matchDisplayValue: false)
                   ?? resolveAnyKeyCode(keyboardShortcut)
            else {
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
              print(" .maskAlphaShift", flags.contains(.maskAlphaShift))
              print(" .maskShift", flags.contains(.maskShift))
              print(" .maskLeftShift", flags.contains(.maskLeftShift))
              print(" .maskRightShift", flags.contains(.maskRightShift))
              print(" .maskControl", flags.contains(.maskControl))
              print(" .maskLeftControl", flags.contains(.maskLeftControl))
              print(" .maskRightControl", flags.contains(.maskRightControl))
              print(" .maskAlternate", flags.contains(.maskAlternate))
              print(" .maskLeftAlternate", flags.contains(.maskLeftAlternate))
              print(" .maskRightAlternate", flags.contains(.maskRightAlternate))
              print(" .maskCommand", flags.contains(.maskCommand))
              print(" .maskLeftCommand", flags.contains(.maskLeftCommand))
              print(" .maskRightCommand", flags.contains(.maskRightCommand))
              print(" .maskHelp", flags.contains(.maskHelp))
              print(" .maskSecondaryFn", flags.contains(.maskSecondaryFn))
              print(" .maskNumericPad", flags.contains(.maskNumericPad))
              print(" .maskNonCoalesced", flags.contains(.maskNonCoalesced))
            }

            if group.userModes.isEmpty {
              let key = createKey(eventSignature: eventSignature,
                                  bundleIdentifier: bundleIdentifier,
                                  userModeKey: "",
                                  previousKey: previousKey)
              let currentPreviousKey = previousKey
              previousKey += "\(eventSignature.id)+"

              if offset == count {
                createDynamicWorkflows(
                  for: workflow,
                  keyCode: Int64(keyCode),
                  flags: flags,
                  bundleIdentifier: bundleIdentifier,
                  userModeKey: "",
                  previousKey: currentPreviousKey
                ) { newKey, match in
                  newCache[newKey] = match
                }
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
                let currentPreviousKey = previousKey
                let key = createKey(eventSignature: eventSignature,
                                    bundleIdentifier: bundleIdentifier,
                                    userModeKey: userModeKey,
                                    previousKey: previousKey)
                if !didSetPreviousKey {
                  previousKey += "\(eventSignature.id)+"
                  didSetPreviousKey = true
                }

                if Self.debug, workflow.name.contains("**") {
                  print(key)
                }

                if offset == count {
                  createDynamicWorkflows(
                    for: workflow,
                    keyCode: Int64(keyCode),
                    flags: flags,
                    bundleIdentifier: bundleIdentifier,
                    userModeKey: userModeKey,
                    previousKey: currentPreviousKey
                  ) { newKey, match in
                    newCache[newKey] = match
                  }
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

  private func createDynamicWorkflows(for workflow: Workflow,
                                      keyCode: Int64,
                                      flags: CGEventFlags,
                                      bundleIdentifier: String,
                                      userModeKey: String,
                                      previousKey: String,
                                      onCreate: (_ key: String, _ match: KeyboardShortcutResult) -> Void) {
    let workspaces = workflow.commands.compactMap {
      if case .bundled(let command) = $0,
         case .workspace(let workspace) = command.kind {
        workspace
      } else {
        nil
      }
    }
    guard let first = workspaces.first else { return }

    let appToggleModifiers = first.appToggleModifiers
    if !appToggleModifiers.isEmpty {
      for modifier in appToggleModifiers {
        var flags = flags
        flags.insert(modifier.cgEventFlags)
        let eventSignature = CGEventSignature(Int64(keyCode), flags)

        let key = createKey(eventSignature: eventSignature,
                            bundleIdentifier: bundleIdentifier,
                            userModeKey: userModeKey,
                            previousKey: previousKey)
        let workflow = Workflow(
          name: "Dynamic Workflow from \(key)",
          commands: [
            .bundled(
              BundledCommand(
                .moveToWorkspace(
                  command: MoveToWorkspaceCommand(
                    id: UUID().uuidString,
                    workspace: first
                  )
                ),
                meta: Command.MetaData()
              )
            )
          ]
        )
        onCreate(key, .exact(workflow))
      }
    }
  }

  private func resolveAnyKeyCode(_ keyShortcut: KeyShortcut) -> Int? {
    keyShortcut.key == KeyShortcut.anyKey.key
    ? KeyShortcut.anyKeyCode
    : nil
  }

  private func createKey(eventSignature: CGEventSignature,
                         bundleIdentifier: String, userModeKey: String,
                         previousKey: String) -> String {
    "\(bundleIdentifier)\(previousKey)\(eventSignature.id)\(userModeKey)"
  }
}

private struct FallbackLookupToken: LookupToken {
  var signature: CGEventSignature { CGEventSignature(keyCode, flags) }

  let keyCode: Int64
  let flags: CGEventFlags
}
