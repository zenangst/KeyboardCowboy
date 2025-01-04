import Carbon
import Testing
@testable import Keyboard_Cowboy

fileprivate let tests: [Test] = [
  // Standard ANSI characters
  Test(key: "a", isEqualTo: kVK_ANSI_A),
  Test(key: "b", isEqualTo: kVK_ANSI_B),
  Test(key: "c", isEqualTo: kVK_ANSI_C),
  Test(key: "d", isEqualTo: kVK_ANSI_D),
  Test(key: "e", isEqualTo: kVK_ANSI_E),
  Test(key: "f", isEqualTo: kVK_ANSI_F),
  Test(key: "g", isEqualTo: kVK_ANSI_G),
  Test(key: "h", isEqualTo: kVK_ANSI_H),
  Test(key: "i", isEqualTo: kVK_ANSI_I),
  Test(key: "j", isEqualTo: kVK_ANSI_J),
  Test(key: "k", isEqualTo: kVK_ANSI_K),
  Test(key: "l", isEqualTo: kVK_ANSI_L),
  Test(key: "m", isEqualTo: kVK_ANSI_M),
  Test(key: "n", isEqualTo: kVK_ANSI_N),
  Test(key: "o", isEqualTo: kVK_ANSI_O),
  Test(key: "p", isEqualTo: kVK_ANSI_P),
  Test(key: "q", isEqualTo: kVK_ANSI_Q),
  Test(key: "r", isEqualTo: kVK_ANSI_R),
  Test(key: "s", isEqualTo: kVK_ANSI_S),
  Test(key: "t", isEqualTo: kVK_ANSI_T),
  Test(key: "u", isEqualTo: kVK_ANSI_U),
  Test(key: "v", isEqualTo: kVK_ANSI_V),
  Test(key: "w", isEqualTo: kVK_ANSI_W),
  Test(key: "x", isEqualTo: kVK_ANSI_X),
  Test(key: "y", isEqualTo: kVK_ANSI_Y),
  Test(key: "z", isEqualTo: kVK_ANSI_Z),
  Test(key: "0", isEqualTo: kVK_ANSI_0),
  Test(key: "1", isEqualTo: kVK_ANSI_1),
  Test(key: "2", isEqualTo: kVK_ANSI_2),
  Test(key: "3", isEqualTo: kVK_ANSI_3),
  Test(key: "4", isEqualTo: kVK_ANSI_4),
  Test(key: "5", isEqualTo: kVK_ANSI_5),
  Test(key: "6", isEqualTo: kVK_ANSI_6),
  Test(key: "7", isEqualTo: kVK_ANSI_7),
  Test(key: "8", isEqualTo: kVK_ANSI_8),
  Test(key: "9", isEqualTo: kVK_ANSI_9),
  Test(key: "`", isEqualTo: kVK_ANSI_Grave),
  Test(key: "~", isEqualTo: kVK_ANSI_Grave),
  Test(key: "-", isEqualTo: kVK_ANSI_Minus),
  Test(key: "_", isEqualTo: kVK_ANSI_Minus),
  Test(key: "=", isEqualTo: kVK_ANSI_Equal),
  Test(key: "+", isEqualTo: kVK_ANSI_Equal),
  Test(key: "[", isEqualTo: kVK_ANSI_LeftBracket),
  Test(key: "{", isEqualTo: kVK_ANSI_LeftBracket),
  Test(key: "]", isEqualTo: kVK_ANSI_RightBracket),
  Test(key: "}", isEqualTo: kVK_ANSI_RightBracket),
  Test(key: "\\", isEqualTo: kVK_ANSI_Backslash),
  Test(key: "|", isEqualTo: kVK_ANSI_Backslash),
  Test(key: ";", isEqualTo: kVK_ANSI_Semicolon),
  Test(key: ":", isEqualTo: kVK_ANSI_Semicolon),
  Test(key: "'", isEqualTo: kVK_ANSI_Quote),
  Test(key: "\"", isEqualTo: kVK_ANSI_Quote),
  Test(key: ",", isEqualTo: kVK_ANSI_Comma),
  Test(key: "<", isEqualTo: kVK_ANSI_Comma),
  Test(key: ".", isEqualTo: kVK_ANSI_Period),
  Test(key: ">", isEqualTo: kVK_ANSI_Period),
  Test(key: "/", isEqualTo: kVK_ANSI_Slash),
  Test(key: "?", isEqualTo: kVK_ANSI_Slash),
  Test(key: " ", isEqualTo: kVK_Space),
  Test(key: "Space", isEqualTo: kVK_Space),

  // Norwegian-specific characters
  Test(key: "å", isEqualTo: kVK_ANSI_Grave),
  Test(key: "Å", isEqualTo: kVK_ANSI_Grave),
  Test(key: "ø", isEqualTo: kVK_ANSI_Semicolon),
  Test(key: "Ø", isEqualTo: kVK_ANSI_Semicolon),
  Test(key: "æ", isEqualTo: kVK_ANSI_Quote),
  Test(key: "Æ", isEqualTo: kVK_ANSI_Quote),

  // Swedish-specific characters
  Test(key: "ä", isEqualTo: kVK_ANSI_Quote),
  Test(key: "Ä", isEqualTo: kVK_ANSI_Quote),
  Test(key: "ö", isEqualTo: kVK_ANSI_Semicolon),
  Test(key: "Ö", isEqualTo: kVK_ANSI_Semicolon),
]

@Test("Test the key code for each letter", arguments: tests)
private func verifyKeyCode(_ test: Test) {
  let lowercase = KeyShortcut(key: test.lowercase)
  let uppercase = KeyShortcut(key: test.uppercase)

  #expect(lowercase.keyCode == test.keyCode)
  #expect(uppercase.keyCode == test.keyCode)
}

fileprivate struct Test {
  let lowercase: String
  let uppercase: String
  let keyCode: Int

  init(key: String, isEqualTo keyCode: Int) {
    self.lowercase = key
    self.uppercase = key.uppercased()
    self.keyCode = keyCode
  }
}
