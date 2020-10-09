import Foundation

/// A `KeyboardShortcut` directly translates into a keyboard shortcut.
/// 
/// They can include modifiers keys such as Control, Option, Command
/// and potentially even the Fn (Function key).
public struct KeyboardShortcutViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public let key: String
  public let modifiers: [ModifierKey]

  public init(id: String = UUID().uuidString,
              key: String,
              modifiers: [ModifierKey] = []) {
    self.id = id
    self.key = key
    self.modifiers = modifiers
  }
}

extension KeyboardShortcutViewModel {
  static func empty() -> KeyboardShortcutViewModel {
    KeyboardShortcutViewModel(key: "")
  }
}
