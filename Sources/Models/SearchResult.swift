import Foundation

public struct SearchResults: Hashable, Equatable {
  public var groups: [WorkflowGroup]
  public var workflows: [Workflow]
  public var commands: [Command]

  public init(groups: [WorkflowGroup] = [], workflows: [Workflow] = [], commands: [Command] = []) {
    self.groups = groups
    self.workflows = workflows
    self.commands = commands
  }

  public static func empty() -> SearchResults {
    SearchResults(groups: [], workflows: [], commands: [])
  }
}

public enum SearchResult {
  case groups([WorkflowGroup])
  case workflows([Workflow])
  case commands([Command])
}
