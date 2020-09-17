import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
public struct Workflow: Codable, Hashable {
  public let commands: [Command]
  public let keyboardShortcuts: [KeyboardShortcut]
  public let name: String

  public init(commands: [Command] = [], keyboardShortcuts: [KeyboardShortcut] = [], name: String) {
    self.commands = commands
    self.keyboardShortcuts = keyboardShortcuts
    self.name = name
  }
}
