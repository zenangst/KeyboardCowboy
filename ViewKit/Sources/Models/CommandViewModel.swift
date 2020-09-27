import Foundation

/// A `Command` is an action that lives inside a `Workflow`
///
/// - Examples: Launching an application, running a script
///             opening a file or folder.
public struct CommandViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public var name: String

  public init(id: String = UUID().uuidString, name: String) {
    self.id = id
    self.name = name
  }
}
