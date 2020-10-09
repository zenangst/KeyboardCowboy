import Foundation

/// A `Command` is an action that lives inside a `Workflow`
///
/// - Examples: Launching an application, running a script
///             opening a file or folder.
public struct CommandViewModel: Identifiable, Hashable, Equatable {
  public let id: String
  public var name: String
  public var kind: Kind

  public init(id: String = UUID().uuidString, name: String, kind: Kind) {
    self.id = id
    self.name = name
    self.kind = kind
  }

  public enum Kind: Identifiable, Hashable, Equatable {
    case application(ApplicationViewModel)
    case keyboard(KeyboardShortcutViewModel)
    case openFile(OpenFileViewModel)
    case openUrl(OpenURLViewModel)
    case appleScript(AppleScriptViewModel)
    case shellScript(ShellScriptViewModel)

    public var id: String {
      switch self {
      case .application:
        return "application"
      case .appleScript:
        return "appleScript"
      case .keyboard:
        return "keyboard"
      case .openFile:
        return "openFile"
      case .openUrl:
        return "openUrl"
      case .shellScript:
        return "shellScript"
      }
    }
  }
}
