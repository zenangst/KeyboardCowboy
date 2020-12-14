import Foundation

/// A `Command` is a polymorphic entity that is used
/// to store multiple command types in the same workflow.
/// All underlying data-types are both `Codable` and `Hashable`.
public enum Command: Identifiable, Codable, Hashable {
  case application(ApplicationCommand)
  case keyboard(KeyboardCommand)
  case open(OpenCommand)
  case script(ScriptCommand)

  public enum CodingKeys: String, CodingKey {
    case application = "applicationCommand"
    case keyboard = "keyboardCommand"
    case open = "openCommand"
    case script = "scriptCommand"
  }

  public var isKeyboardBinding: Bool {
    switch self {
    case .keyboard:
      return true
    default:
      return false
    }
  }

  public var name: String {
    switch self {
    case .application(let command):
      return command.name.isEmpty ? "Open \(command.application.displayName)" : command.name
    case .keyboard(let command):
      var keyboardShortcut = command.keyboardShortcut.modifiers?.compactMap({ $0.pretty }).joined() ?? ""
      keyboardShortcut += command.keyboardShortcut.key
      return command.name.isEmpty ? "Run a Keyboard Shortcut: \(keyboardShortcut)" : command.name
    case .open(let command):
      if !command.name.isEmpty { return command.name }
      if command.isUrl {
        return "Open a URL: \(command.path)"
      } else {
        return "Open a file: \(command.path)"
      }
    case .script(let command):
      switch command {
      case .appleScript:
        return "Run Apple Script"
      case .shell:
        return "Run Shellscript"
      }
    }
  }

  public var id: String {
    switch self {
    case .application(let command):
      return command.id
    case .keyboard(let command):
      return command.id
    case .open(let command):
      return command.id
    case .script(let command):
      return command.id
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    switch container.allKeys.first {
    case .application:
      let command = try container.decode(ApplicationCommand.self, forKey: .application)
      self = .application(command)
    case .keyboard:
      let command = try container.decode(KeyboardCommand.self, forKey: .keyboard)
      self = .keyboard(command)
    case .open:
      let command = try container.decode(OpenCommand.self, forKey: .open)
      self = .open(command)
    case .script:
      let command = try container.decode(ScriptCommand.self, forKey: .script)
      self = .script(command)
    case .none:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .application(let command):
      try container.encode(command, forKey: .application)
    case .keyboard(let command):
      try container.encode(command, forKey: .keyboard)
    case .open(let command):
      try container.encode(command, forKey: .open)
    case .script(let command):
      try container.encode(command, forKey: .script)
    }
  }
}

public extension Command {
  static func empty(_ kind: CodingKeys) -> Command {
    switch kind {
    case .application:
      return Command.application(ApplicationCommand.empty())
    case .keyboard:
      return Command.keyboard(KeyboardCommand.empty())
    case .open:
      return Command.open(.init(path: ""))
    case .script:
      return Command.script(.appleScript(.path(""), ""))
    }
  }
}
