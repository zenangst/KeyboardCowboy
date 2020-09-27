import Foundation

/// A `Combination` directly translates into a keyboard shortcut.
/// 
/// They can include modifiers keys such as Control, Option, Command
/// and potentially even the Fn (Function key).
public struct CombinationViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  let name: String

  public init(id: String = UUID().uuidString, name: String) {
    self.id = id
    self.name = name
  }
}
