import Foundation

/// A `Command` is an action that lives inside a `Workflow`
///
/// - Examples: Launching an application, running a script
///             opening a file or folder.
public struct CommandViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public var name: String
  public let kind: Kind

  public init(id: String = UUID().uuidString, name: String, kind: Kind) {
    self.id = id
    self.name = name
    self.kind = kind
  }

  public enum Kind: Hashable, Equatable {
    case application(path: String, bundleIdentifier: String)
    case keyboard
    case openFile(path: String, application: String)
    case openUrl(url: String, application: String)
    case appleScript
    case shellScript
  }
}
