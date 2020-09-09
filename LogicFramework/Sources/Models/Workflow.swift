import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
public struct Workflow: Codable, Hashable {
  public let combinations: [Combination]
  public let commands: [Command]
  public let name: String

  public init(combinations: [Combination] = [], commands: [Command] = [], name: String) {
    self.combinations = combinations
    self.commands = commands
    self.name = name
  }
}
