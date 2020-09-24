import Foundation

/// A `Combination` directly translates into a keyboard shortcut.
/// 
/// They can include modifiers keys such as Control, Option, Command
/// and potentially even the Fn (Function key).
public struct CombinationViewModel: Identifiable, Hashable {
  public let id: String = UUID().uuidString
  let name: String

  public init(name: String) {
    self.name = name
  }
}
