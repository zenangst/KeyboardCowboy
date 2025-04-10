import Carbon
import XCTest
import KeyCodes
import InputSources
@testable import MachPort
@testable import Keyboard_Cowboy

@MainActor
final class ShortcutResolverTests: XCTestCase {
  static let rootPath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  func testShortcutResolverLookupSingleKeyTrigger() {
    let keyShortcut = KeyShortcut(key: "s", modifiers: [.leftCommand])
    let trigger = Workflow.Trigger.keyboardShortcuts(KeyboardShortcutTrigger(shortcuts: [keyShortcut]))
    let command = Command.systemCommand(.init(kind: .activateLastApplication, meta: Command.MetaData()))
    let workflow = Workflow(name: "workflow", trigger: trigger, commands: [command])
    let group = WorkflowGroup(name: "group", workflows: [workflow])

    let keyCodes = KeyCodeLoookupMock(cache: ["s": 1])
    let shortcutResolver = ShortcutResolver(keyCodes: keyCodes)
    shortcutResolver.cache([group])

    let mismatchedToken = LookupTokenMock(keyCode: 0, flags: .maskCommand)
    let matchedToken = LookupTokenMock(keyCode: 1, flags: keyShortcut.cgFlags)

    XCTAssertFalse((shortcutResolver.lookup(mismatchedToken, bundleIdentifier: "*.", userModes: []) != nil))
    XCTAssertTrue((shortcutResolver.lookup(matchedToken, bundleIdentifier: "*.", userModes: []) != nil))
  }

  func testShortcutResolverLookupSequenceKeyTrigger() {
    let keyShortcut1 = KeyShortcut(key: "s", modifiers: [.leftCommand])
    let keyShortcut2 = KeyShortcut(key: "a", modifiers: [.leftCommand])
    let trigger = Workflow.Trigger.keyboardShortcuts(
      KeyboardShortcutTrigger(shortcuts: [keyShortcut1, keyShortcut2])
    )
    let command = Command.systemCommand(.init(kind: .activateLastApplication, meta: Command.MetaData()))
    let workflow = Workflow(name: "workflow", trigger: trigger, commands: [command])
    let group = WorkflowGroup(name: "group", workflows: [workflow])

    let keyCodes = KeyCodeLoookupMock(cache: ["a": 0, "s": 1])
    let shortcutResolver = ShortcutResolver(keyCodes: keyCodes)
    shortcutResolver.cache([group])

    let mismatchedToken = LookupTokenMock(keyCode: 0, flags: .maskCommand)

    let matchedToken1 = LookupTokenMock(keyCode: 1, flags: keyShortcut1.cgFlags)
    let matchedToken2 = LookupTokenMock(keyCode: 0, flags: keyShortcut1.cgFlags)

    XCTAssertFalse((shortcutResolver.lookup(mismatchedToken, bundleIdentifier: "*.", userModes: []) != nil))

    let partialMatch = shortcutResolver.lookup(matchedToken1, bundleIdentifier: "*.", userModes: [])

    switch partialMatch {
    case .partialMatch(let partialMatch):
      switch shortcutResolver.lookup(matchedToken2, bundleIdentifier: "*.", userModes: [], partialMatch: partialMatch) {
      case .exact(let resolvedWorkflow):
        print("workflow", workflow.name)
        XCTAssertEqual(workflow, resolvedWorkflow)
      case .partialMatch, .none:
        XCTFail("Unable to resolve partial match")
      }

    case .exact, .none:
      XCTFail("Unable to resolve partial match")
    }
  }
}

@MainActor
fileprivate class KeyCodeLoookupMock: KeycodeLocating {
  func specialKeys() -> [Int : String] { [:] }

  func displayValue(for keyCode: Int, modifiers: [VirtualModifierKey]) -> String? { nil }

  var cache: [String: Int]

  init(cache: [String : Int]) {
    self.cache = cache
  }

  func keyCode(for string: String, matchDisplayValue: Bool) -> Int? {
    return cache[string]
  }
}

fileprivate struct LookupTokenMock: LookupToken {
  var keyCode: Int64
  var signature: CGEventSignature
  var flags: CGEventFlags

  init(keyCode: Int64, flags: CGEventFlags) {
    self.keyCode = keyCode
    self.flags = flags
    self.signature = CGEventSignature(keyCode, flags)
  }
}
