import Carbon
import CoreGraphics
import Foundation
import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers

@Test(arguments: [0, 1, 2])
func prefersExactDisplayThenLowercaseDisplayThenLowercaseRaw(rank: Int) {
  let compiler = Triggers.Compiler { key, display in
    switch (key, display) {
    case ("A", true) where rank == 0: 10
    case ("a", true) where rank <= 1: 11
    case ("a", false): 12
    default: nil
    }
  }
  #expect(compiler.signature(for: .init(key: "A"))?.keyCode == UInt16(10 + rank))
}

@Test func decodedShortcutMatchesInputWithoutCollapsingModifierSides() throws {
  let data = Data(#"{"id":"legacy","key":"A","modifiers":["r@","$"]}"#.utf8)
  let shortcut = try JSONDecoder().decode(Triggers.SavedShortcut.self, from: data)
  let compiler = Triggers.Compiler { key, display in key == "a" && display ? kVK_ANSI_A : nil }
  let binding = try #require(compiler.signature(for: shortcut))
  let expected = CGEventFlags([.maskNonCoalesced, .maskCommand, .maskShift]).rawValue | 0x12
  let event = try #require(Triggers.Signature(eventKeyCode: Int64(kVK_ANSI_A), flags: expected))
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "example", signature: binding)])
  #expect(matcher.match(event, frontmostBundleIdentifier: nil) == "example")
  for flags in [expected ^ 0x18, expected | (1 << 63)] {
    let other = try #require(Triggers.Signature(eventKeyCode: Int64(kVK_ANSI_A), flags: flags))
    #expect(matcher.match(other, frontmostBundleIdentifier: nil) == nil)
  }
  let noModifiers = try JSONDecoder().decode(Triggers.SavedShortcut.self, from: Data(#"{"key":"a"}"#.utf8))
  #expect(compiler.signature(for: noModifiers)?.flags == CGEventFlags.maskNonCoalesced.rawValue)
}

private let specialKeys: [(Int, CGEventFlags)] = [
  (kVK_F1, .maskSecondaryFn),
  (kVK_Home, .maskSecondaryFn),
  (kVK_LeftArrow, [.maskNumericPad, .maskSecondaryFn]),
  (kVK_ANSI_KeypadEnter, [.maskNumericPad, .maskSecondaryFn]),
  (kVK_ANSI_KeypadDecimal, .maskNumericPad),
  (kVK_ANSI_Keypad1, .maskNumericPad),
  (kVK_ANSI_F, []),
]

@Test(arguments: specialKeys)
func appliesLegacyTriggerFlagsByResolvedKeyCode(code: Int, additionalFlags: CGEventFlags) {
  let compiler = Triggers.Compiler { _, _ in code }
  #expect(compiler.signature(for: .init(key: "F"))?.flags == additionalFlags.union(.maskNonCoalesced).rawValue)
}

@Test func rejectsUnresolvedInvalidAndSequenceOnlyKeys() {
  let compiler = Triggers.Compiler { key, _ in
    switch key {
    case "negative": -1
    case "oversized": Int(UInt16.max) + 1
    case "any", "": 0
    default: nil
    }
  }
  for key in ["negative", "oversized", "any", "", "unresolved"] {
    #expect(compiler.signature(for: .init(key: key)) == nil)
  }
  #expect(Triggers.Signature(eventKeyCode: -1, flags: 0) == nil)
  #expect(Triggers.Signature(eventKeyCode: Int64(UInt16.max) + 1, flags: 0) == nil)
}
