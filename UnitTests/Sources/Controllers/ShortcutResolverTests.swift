import Carbon
import XCTest
import KeyCodes
import InputSources
@testable import MachPort
@testable import Keyboard_Cowboy

final class ShortcutResolverTests: XCTestCase {
  static let rootPath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  func testShortcutResolverLookupSingleKeyTrigger() {
    let keyShortcut = KeyShortcut(key: "s", modifiers: [.command])
    let trigger = Workflow.Trigger.keyboardShortcuts(KeyboardShortcutTrigger(shortcuts: [keyShortcut]))
    let command = Command.systemCommand(.init(kind: .activateLastApplication, meta: Command.MetaData()))
    let workflow = Workflow(name: "workflow", trigger: trigger, commands: [command])
    let group = WorkflowGroup(name: "group", workflows: [workflow])

    let keyCodes = KeyCodeLoookupMock(cache: ["s": 1])
    let shortcutResolver = ShortcutResolver(keyCodes: keyCodes)
    shortcutResolver.cache([group])

    let mismatchedToken = LookupTokenMock(lhs: true, keyCode: 0, flags: .maskCommand)
    let matchedToken = LookupTokenMock(lhs: true, keyCode: 1, flags: keyShortcut.cgFlags)

    XCTAssertFalse((shortcutResolver.lookup(mismatchedToken, bundleIdentifier: "*.", userModes: []) != nil))
    XCTAssertTrue((shortcutResolver.lookup(matchedToken, bundleIdentifier: "*.", userModes: []) != nil))
  }

  func testShortcutResolverLookupSequenceKeyTrigger() {
    let keyShortcut1 = KeyShortcut(key: "s", modifiers: [.command])
    let keyShortcut2 = KeyShortcut(key: "a", modifiers: [.command])
    let trigger = Workflow.Trigger.keyboardShortcuts(
      KeyboardShortcutTrigger(shortcuts: [keyShortcut1, keyShortcut2])
    )
    let command = Command.systemCommand(.init(kind: .activateLastApplication, meta: Command.MetaData()))
    let workflow = Workflow(name: "workflow", trigger: trigger, commands: [command])
    let group = WorkflowGroup(name: "group", workflows: [workflow])

    let keyCodes = KeyCodeLoookupMock(cache: ["a": 0, "s": 1])
    let shortcutResolver = ShortcutResolver(keyCodes: keyCodes)
    shortcutResolver.cache([group])

    let mismatchedToken = LookupTokenMock(lhs: true, keyCode: 0, flags: .maskCommand)

    let matchedToken1 = LookupTokenMock(lhs: true, keyCode: 1, flags: keyShortcut1.cgFlags)
    let matchedToken2 = LookupTokenMock(lhs: true, keyCode: 0, flags: keyShortcut1.cgFlags)

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

  // https://github.com/zenangst/KeyboardCowboy/issues/562
  func testFix562() throws {
    let fixture = Self.rootPath.appending(path: "Fixtures/json/example_config/bug_562.json")
    let fileManager = FileManager.default
    guard let data = fileManager.contents(atPath: fixture.path()) else {
      XCTFail("Unable to read file")
      return
    }

    let decoder = JSONDecoder()
    let configurations = try decoder.decode([KeyboardCowboyConfiguration].self, from: data)

    XCTAssertEqual(configurations.count, 1)

    let configuration = configurations.first!
    let keyCodes = KeyCodesStore(InputSourceController())
    let shortcutResolver = ShortcutResolver(keyCodes: keyCodes)

    shortcutResolver.cache(configuration.groups)

    // Verify F13
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_F13), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Copy")
      default: XCTFail("")
      }
    }

    // Verify F16
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_F16), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Reload Tab")
      default: XCTFail("")
      }
    }

    // Verify F18
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_F18), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Previous Tab")
      default: XCTFail("")
      }
    }

    // Verify F19
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_F19), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "New Tab")
      default: XCTFail("")
      }
    }

    // Verify F20
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_F20), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Paste")
      default: XCTFail("")
      }
    }

    // Verify Home
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_Home), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "com.spotify.client"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Volume Up")
      default: XCTFail("")
      }
    }

    // Verify End
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(lhs: true, keyCode: Int64(kVK_End), flags: CGEventFlags(arrayLiteral: [.maskSecondaryFn, .maskNonCoalesced])),
        bundleIdentifier: "com.spotify.client"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Volume Down")
      default: XCTFail("")
      }
    }

    // Verify Command + Control + Shift + Option + Left Arrow
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(
          lhs: true,
          keyCode: Int64(kVK_LeftArrow),
          flags: CGEventFlags(
            arrayLiteral: [
              .maskShift,
              .init(rawValue: UInt64(NX_DEVICELSHIFTKEYMASK)),
              .maskControl,
              .init(rawValue: UInt64(NX_DEVICELCTLKEYMASK)),
              .maskAlternate,
              .init(rawValue: UInt64(NX_DEVICELALTKEYMASK)),
              .maskCommand,
              .init(rawValue: UInt64(NX_DEVICELCMDKEYMASK)),
              .maskSecondaryFn,
              .maskNumericPad,
              .maskNonCoalesced]
          )
        ),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Next Tab")
      default: XCTFail("")
      }
    }

    // Verify Command + Control + Shift + Option + Right Arrow
    do {
      switch shortcutResolver.lookup(
        LookupTokenMock(
          lhs: true,
          keyCode: Int64(kVK_RightArrow),
          flags: CGEventFlags(
            arrayLiteral: [
              .maskShift,
              .init(rawValue: UInt64(NX_DEVICELSHIFTKEYMASK)),
              .maskControl,
              .init(rawValue: UInt64(NX_DEVICELCTLKEYMASK)),
              .maskAlternate,
              .init(rawValue: UInt64(NX_DEVICELALTKEYMASK)),
              .maskCommand,
              .init(rawValue: UInt64(NX_DEVICELCMDKEYMASK)),
              .maskSecondaryFn,
              .maskNumericPad,
              .maskNonCoalesced]
          )
        ),
        bundleIdentifier: "*"
      ) {
      case .exact(let workflow): XCTAssertEqual(workflow.name, "Close Tab")
      default: XCTFail("")
      }
    }
  }
}

fileprivate class KeyCodeLoookupMock: KeycodeLocating {
  var cache: [String: Int]

  init(cache: [String : Int]) {
    self.cache = cache
  }

  func keyCode(for string: String, matchDisplayValue: Bool) -> Int? {
    return cache[string]
  }
}

fileprivate struct LookupTokenMock: LookupToken {
  var lhs: Bool
  var signature: CGEventSignature

  init(lhs: Bool = true, keyCode: Int64, flags: CGEventFlags) {
    self.lhs = lhs
    self.signature = CGEventSignature(keyCode, flags)
  }
}
