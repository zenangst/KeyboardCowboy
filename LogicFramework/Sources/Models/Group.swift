import Foundation

/// A group is a collection of `Workflow`s. Eligability is determined
/// by the collection of rules that the `Group` also holds reference to.
///
/// - Note: `[Rule]` are used to determine if a
///          collection of workflows are eligible to be invoked.
///          All rules have to return `true` for workflows to be
///          eligable for execution.
public struct Group: Codable, Hashable {
  public let name: String
  public let rule: Rule?
  public let workflows: [Workflow]
}
