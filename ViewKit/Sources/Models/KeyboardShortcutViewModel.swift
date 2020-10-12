import Foundation

/// A `KeyboardShortcut` directly translates into a keyboard shortcut.
/// 
/// They can include modifiers keys such as Control, Option, Command
/// and potentially even the Fn (Function key).
public struct KeyboardShortcutViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public let index: Int
  public var key: String
  public var modifiers: [ModifierKey]

  public init(id: String = UUID().uuidString,
              index: Int,
              key: String,
              modifiers: [ModifierKey] = []) {
    self.id = id
    self.index = index
    self.key = key
    self.modifiers = modifiers
  }
}

extension KeyboardShortcutViewModel {
  static func empty() -> KeyboardShortcutViewModel {
    KeyboardShortcutViewModel(index: 1, key: "")
  }
}
