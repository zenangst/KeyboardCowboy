import Carbon

public extension KeyCodeSystem {
  static let specialKeys: [Int: String] = {
    var keys = [
      kVK_Space: "Space", kVK_CapsLock: "Caps Lock", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
      kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
      kVK_End: "↘", kVK_Home: "↖", kVK_Escape: "⎋", kVK_PageDown: "⇟", kVK_PageUp: "⇞",
      kVK_Return: "↩", kVK_ANSI_KeypadEnter: "⌅", kVK_Tab: "⇥", kVK_Help: "?⃝",
    ]
    for (index, code) in functionKeys.enumerated() { keys[code] = "F\(index + 1)" }
    for (digit, code) in keypadDigits.enumerated() { keys[code] = "#\(digit)" }
    return keys
  }()

  private static let functionKeys = [
    kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
    kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
  ]

  private static let keypadDigits = [
    kVK_ANSI_Keypad0, kVK_ANSI_Keypad1, kVK_ANSI_Keypad2, kVK_ANSI_Keypad3, kVK_ANSI_Keypad4,
    kVK_ANSI_Keypad5, kVK_ANSI_Keypad6, kVK_ANSI_Keypad7, kVK_ANSI_Keypad8, kVK_ANSI_Keypad9,
  ]

  internal static let specialCodes = Dictionary(uniqueKeysWithValues: specialKeys.map { ($0.value, $0.key) })

  private static let keypad = Set(keypadDigits + [
    kVK_ANSI_KeypadDecimal, kVK_ANSI_KeypadMultiply, kVK_ANSI_KeypadPlus, kVK_ANSI_KeypadClear,
    kVK_ANSI_KeypadDivide, kVK_ANSI_KeypadEnter, kVK_ANSI_KeypadMinus, kVK_ANSI_KeypadEquals,
    kVK_JIS_KeypadComma,
  ])

  internal static let lookupOrder = (0 ..< 128).filter { !keypad.contains($0) } + (0 ..< 128).filter { keypad.contains($0) }
}
