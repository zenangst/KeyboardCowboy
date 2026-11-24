import Carbon
import CoreGraphics
import KeyCodeSystem
import Testing

@MainActor @Test func bundledLayoutsTranslateTheSamePhysicalKeyDifferently() throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  #expect(us.displayValue(for: kVK_ANSI_Q) == "q")
  #expect(french.displayValue(for: kVK_ANSI_Q) == "a")
  #expect(us.keyCode(for: "a") == kVK_ANSI_A)
  #expect(french.keyCode(for: "a") == kVK_ANSI_Q)
  #expect(french.keyCode(for: "é") == kVK_ANSI_2)
}

@MainActor @Test func shiftedOptionAndDeadKeyTranslationsAreIndependent() throws {
  let layout = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  #expect(layout.keyCode(for: "A") == nil)
  #expect(layout.keyCode(for: "A", modifiers: .maskShift) == kVK_ANSI_A)
  #expect(layout.keyCode(for: "!", modifiers: .maskShift) == kVK_ANSI_1)
  #expect(layout.keyCode(for: "å", modifiers: .maskAlternate) == kVK_ANSI_A)
  #expect(layout.keyCode(for: "Å", modifiers: [.maskAlternate, .maskShift]) == kVK_ANSI_A)
  #expect(layout.displayValue(for: kVK_ANSI_E, modifiers: .maskAlternate) == "´")
  #expect(layout.displayValue(for: kVK_ANSI_A) == "a")
  #expect(layout.keyCode(for: "a", modifiers: [.maskSecondaryFn, .maskNonCoalesced]) == kVK_ANSI_A)
  #expect(layout.displayValue(for: kVK_ANSI_A, modifiers: .maskAlphaShift) == "A")
  #expect(layout.keyCode(for: "A", modifiers: .maskAlphaShift) == kVK_ANSI_A)
}

@MainActor @Test func specialLabelsRoundTripAndRawCollisionsPreferTheMainKeyboard() throws {
  let layout = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  #expect(KeyCodeSystem.specialKeys.count == 47)
  #expect(KeyCodeSystem.specialKeys[kVK_F20] == "F20")
  #expect(KeyCodeSystem.specialKeys[kVK_LeftArrow] == "←")
  #expect(KeyCodeSystem.specialKeys[kVK_ANSI_KeypadEnter] == "⌅")
  for (code, name) in KeyCodeSystem.specialKeys {
    #expect(layout.displayValue(for: code) == name)
    #expect(layout.keyCode(for: name) == code)
    #expect(layout.keyCode(for: name, modifiers: [.maskShift, .maskAlternate]) == code)
  }
  #expect(layout.keyCode(for: "#1") == kVK_ANSI_Keypad1)
  #expect(layout.keyCode(for: "1") == kVK_ANSI_1)
  #expect(layout.keyCode(for: "1", matchDisplayValue: false) == kVK_ANSI_1)
  #expect(layout.keyCode(for: "+", matchDisplayValue: false) == kVK_ANSI_KeypadPlus)
  #expect(layout.rawValue(for: kVK_Space) == " ")
  #expect(layout.keyCode(for: " ", matchDisplayValue: false) == kVK_Space)
  #expect(layout.keyCode(for: " ") == nil)
  #expect(layout.rawValue(for: kVK_Return) == "\r")
  #expect(layout.displayValue(for: kVK_Return) == "↩")
}

@MainActor @Test func missingSourcesAndInvalidLookupsReturnExplicitMisses() throws {
  let missing = "com.keyboardcowboy.nonexistent-test-layout"
  #expect(throws: KeyCodeSystem.LookupError.inputSourceUnavailable(missing)) {
    try KeyCodeSystem.Layout(inputSourceID: missing)
  }
  let layout = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  #expect(layout.displayValue(for: -1) == nil)
  #expect(layout.rawValue(for: 128) == nil)
  #expect(layout.keyCode(for: "") == nil)
  #expect(layout.keyCode(for: "not a key") == nil)
}

@MainActor @Test func currentLayoutIsAvailableWithoutSelectingAnInputSource() throws {
  let layout = try KeyCodeSystem.Layout.current()
  #expect(layout.keyCode(for: "F1") == kVK_F1)
}
