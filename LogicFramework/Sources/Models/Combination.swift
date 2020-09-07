import Foundation

/// Combination is a data-structure that directly
/// translates into a keyboard shortcut. This is
/// used to match if a certain `Workflow` is eligiable
/// to be invoked.
public struct Combination: Codable, Hashable {
  public let input: String
}
