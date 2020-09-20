import Carbon

public class Hotkey: Hashable {
  let keyboardShortcut: KeyboardShortcut
  let keyCode: Int
  var identifier: EventHotKeyID?
  var reference: EventHotKeyRef?
  var modifiers: Int {
    var carbonFlags: Int = 0
    guard let modifiers = keyboardShortcut.modifiers else { return carbonFlags }

    if modifiers.contains(.command) == true {
      carbonFlags |= cmdKey
    }
    if modifiers.contains(.option) == true {
      carbonFlags |= optionKey
    }
    if modifiers.contains(.control) == true {
      carbonFlags |= controlKey
    }
    if modifiers.contains(.shift) == true {
      carbonFlags |= shiftKey
    }

    return carbonFlags
  }

  public init(keyboardShortcut: KeyboardShortcut, keyCode: Int) {
    self.keyboardShortcut = keyboardShortcut
    self.keyCode = keyCode
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(keyboardShortcut)
  }

  public static func == (lhs: Hotkey, rhs: Hotkey) -> Bool {
    lhs.keyboardShortcut == rhs.keyboardShortcut
  }
}
