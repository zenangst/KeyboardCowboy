import Carbon
import CoreGraphics
import KeyCodeSystem

public extension KeyboardTriggers {
  struct Compiler: Sendable {
    public typealias Lookup = @Sendable (_ key: String, _ matchDisplayValue: Bool) -> Int?
    private let lookup: Lookup

    public init(lookup: @escaping Lookup) {
      self.lookup = lookup
    }

    public init(layout: KeyCodeSystem.Layout) {
      self.init { layout.keyCode(for: $0, matchDisplayValue: $1) }
    }

    /// Compiles a saved binding, not a key-posting request. `any` is reserved for sequence matching.
    public func signature(for shortcut: SavedShortcut) -> Signature? {
      guard !shortcut.key.isEmpty, shortcut.key != "any" else { return nil }

      let lowercased = shortcut.key.lowercased()
      guard let code = lookup(shortcut.key, true) ?? lookup(lowercased, true) ?? lookup(lowercased, false),
            let keyCode = UInt16(exactly: code) else { return nil }

      var flags = shortcut.modifiers.reduce(into: CGEventFlags.maskNonCoalesced) { $0.formUnion($1.flags) }
      if Self.functionKeys.contains(code) { flags.insert(.maskSecondaryFn) }
      if Self.numericPadKeys.contains(code) { flags.insert(.maskNumericPad) }
      return Signature(keyCode: keyCode, flags: flags.rawValue)
    }

    /// Does not shorten a binding when a step cannot be resolved.
    public func signatures(for shortcuts: [SavedShortcut]) -> [Signature]? {
      guard !shortcuts.isEmpty else { return nil }

      var signatures: [Signature] = []
      for shortcut in shortcuts {
        guard let signature = signature(for: shortcut) else { return nil }

        signatures.append(signature)
      }
      return signatures
    }

    /// A saved `any` is valid only as an unmodified final step after a fixed prefix.
    public func sequence(for shortcuts: [SavedShortcut]) -> CompiledSequence? {
      let endsWithAnyKey = shortcuts.last?.key == "any"
      if endsWithAnyKey, shortcuts.last?.modifiers.isEmpty != true { return nil }
      let fixed = endsWithAnyKey ? Array(shortcuts.dropLast()) : shortcuts
      guard let signatures = signatures(for: fixed), let first = signatures.first else { return nil }

      return CompiledSequence(signature: first, continuation: Array(signatures.dropFirst()), endsWithAnyKey: endsWithAnyKey)
    }

    private static let arrows: Set<Int> = [kVK_UpArrow, kVK_DownArrow, kVK_LeftArrow, kVK_RightArrow]
    static let functionKeys = arrows.union([
      kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
      kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
      kVK_Home, kVK_End, kVK_PageUp, kVK_PageDown, kVK_ANSI_KeypadEnter, kVK_JIS_KeypadComma,
    ])
    private static let numericPadKeys = arrows.union([
      kVK_ANSI_Keypad0, kVK_ANSI_Keypad1, kVK_ANSI_Keypad2, kVK_ANSI_Keypad3, kVK_ANSI_Keypad4,
      kVK_ANSI_Keypad5, kVK_ANSI_Keypad6, kVK_ANSI_Keypad7, kVK_ANSI_Keypad8, kVK_ANSI_Keypad9,
      kVK_ANSI_KeypadDecimal, kVK_ANSI_KeypadMultiply, kVK_ANSI_KeypadPlus, kVK_ANSI_KeypadClear,
      kVK_ANSI_KeypadDivide, kVK_ANSI_KeypadEnter, kVK_ANSI_KeypadMinus, kVK_ANSI_KeypadEquals, kVK_JIS_KeypadComma,
    ])
  }
}
