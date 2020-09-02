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
struct Group: Identifiable, Hashable {
  let id: String = UUID().uuidString
  let name: String
  var workflows: [Workflow]
}
