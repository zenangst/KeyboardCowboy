import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
public struct KeyboardCommand: Codable, Hashable {
  public let keyboardShortcut: KeyboardShortcut

  public init(keyboardShortcut: KeyboardShortcut) {
    self.keyboardShortcut = keyboardShortcut
  }
}
