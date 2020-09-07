import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
public struct Workflow: Codable, Hashable {
  public let commands: [Command]
  /// TODO: Add `Combination` model in order to determine
  ///       is a workflow is eligiable for invocation.
  public let name: String
}
