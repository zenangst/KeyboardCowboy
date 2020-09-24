import Foundation

/// A `Command` is an action that lives inside a `Workflow`
///
/// - Examples: Launching an application, running a script
///             opening a file or folder.
public struct CommandViewModel: Identifiable, Hashable {
  public let id: String = UUID().uuidString
  public var name: String

  public init(name: String) {
    self.name = name
  }
}
