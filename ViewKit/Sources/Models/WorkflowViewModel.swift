import Foundation

/// A `Workflow` is a collection of commands that will be invoked
/// in sequence. They are triggered by a single or multiple `Combination`'s.
/// When working with a collection of `Combination`'s, the application will use
/// Emacs binding to perform the correct commands. `Workflows` can share the same
/// first, second or third set of `Combination`´s but never the last.
///
/// - Note: `Combination` uniqueness needs to work across multiple `Workflow`'s.
public struct WorkflowViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public var name: String
  public var keyboardShortcuts: [KeyboardShortcutViewModel]
  public var commands: [CommandViewModel]

  public init(id: String,
              name: String,
              keyboardShortcuts: [KeyboardShortcutViewModel],
              commands: [CommandViewModel]) {
    self.id = id
    self.name = name
    self.keyboardShortcuts = keyboardShortcuts
    self.commands = commands
  }
}
