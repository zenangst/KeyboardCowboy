import Foundation

/// A `Workflow` is a collection of commands that will be invoked
/// in sequence. They are triggered by a single or multiple `Combination`'s.
/// When working with a collection of `Combination`'s, the application will use
/// Emacs binding to perform the correct commands. `Workflows` can share the same
/// first, second or third set of `Combination`´s but never the last.
///
/// - Note: `Combination` uniqueness needs to work across multiple `Workflow`'s.
public struct WorkflowViewModel: Identifiable, Hashable {
  public let id: String = UUID().uuidString
  public var name: String
  public var combinations: [CombinationViewModel]
  public var commands: [CommandViewModel]

  public init(name: String, combinations: [CombinationViewModel], commands: [CommandViewModel]) {
    self.name = name
    self.combinations = combinations
    self.commands = commands
  }
}
