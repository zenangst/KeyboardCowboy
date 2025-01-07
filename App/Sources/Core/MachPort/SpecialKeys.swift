import Carbon

struct SpecialKeys {
  static let functionKeys: Set<Int> = [
    kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6,
    kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12,
    kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18,
    kVK_F19, kVK_F20,

    kVK_Home,
    kVK_End,
    kVK_PageUp,
    kVK_PageDown,

    kVK_UpArrow,
    kVK_DownArrow,
    kVK_LeftArrow,
    kVK_RightArrow,
    kVK_ANSI_KeypadEnter,
    kVK_JIS_KeypadComma,
  ]

  static let numericPadKeys: Set<Int> = [
    kVK_UpArrow,
    kVK_DownArrow,
    kVK_LeftArrow,
    kVK_RightArrow,
    kVK_ANSI_KeypadDecimal,
    kVK_ANSI_KeypadMultiply,
    kVK_ANSI_KeypadPlus,
    kVK_ANSI_KeypadClear,
    kVK_ANSI_KeypadDivide,
    kVK_ANSI_KeypadEnter,
    kVK_ANSI_KeypadMinus,
    kVK_ANSI_KeypadEquals,
    kVK_ANSI_Keypad0,
    kVK_ANSI_Keypad1,
    kVK_ANSI_Keypad2,
    kVK_ANSI_Keypad3,
    kVK_ANSI_Keypad4,
    kVK_ANSI_Keypad5,
    kVK_ANSI_Keypad6,
    kVK_ANSI_Keypad7,
    kVK_ANSI_Keypad8,
    kVK_ANSI_Keypad9,
    kVK_JIS_KeypadComma,
  ]
}
