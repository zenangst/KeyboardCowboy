import Foundation

/// A `Group` is a collection of `Workflow`s.
/// They are used to group collections but also to scope
/// the validity of the `Workflow`'s. This should work with
/// a set of rules determining if a workflow is enabled or not.
///
/// - Example: A group can be scoped to only be active when a
///            certain application is active, such as:
///            The group `Finder workflows` will only apply
///            and be bound to keyboard shortcuts when the Finder
///            is the front-most application.
public struct GroupViewModel: Identifiable, Hashable {
  public let id: String
  public var name: String
  public var workflows: [WorkflowViewModel]

  public init(id: String, name: String, workflows: [WorkflowViewModel]) {
    self.id = id
    self.name = name
    self.workflows = workflows
  }
}
