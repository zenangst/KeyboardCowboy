import Foundation

/// Keyboard shortcut is a data-structure that directly
/// translates into a keyboard shortcut. This is
/// used to match if a certain `Workflow` is eligiable
/// to be invoked.
public struct KeyboardShortcut: Codable, Hashable {
  public let key: String
  public let modifiers: [ModifierKey]?

  public var rawValue: String {
    var input: String = (modifiers ?? []).compactMap({ $0.rawValue }).joined()
    input.append(key)
    return input
  }

  public init(key: String, modifiers: [ModifierKey]? = nil) {
    self.key = key
    self.modifiers = modifiers
  }
}
