import Apps
import Foundation

/// A `Command` is a polymorphic entity that is used
/// to store multiple command types in the same workflow.
/// All underlying data-types are both `Codable` and `Hashable`.
public enum Command: Identifiable, Codable, Hashable, Sendable {
  case application(ApplicationCommand)
  case builtIn(BuiltInCommand)
  case keyboard(KeyboardCommand)
  case open(OpenCommand)
  case script(ScriptCommand)
  case type(TypeCommand)

  public enum CodingKeys: String, CodingKey {
    case application = "applicationCommand"
    case builtIn = "builtInCommand"
    case keyboard = "keyboardCommand"
    case open = "openCommand"
    case script = "scriptCommand"
    case type = "typeCommand"
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
    get {
      switch self {
      case .application(let command):
        return command.name.isEmpty ? "\(command.action.displayValue) \(command.application.displayName)" : command.name
      case .builtIn(let command):
        return command.name
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
        return command.name
      case .type(let command):
        return command.name
      }
    }
    set {
      switch self {
      case .application(var command):
        command.name = newValue
      case .builtIn:
        break
      case .keyboard(var command):
        command.name = newValue
      case .open(var command):
        command.name = newValue
      case .script(let command):
        switch command {
        case .appleScript(let id, let isEnabled, _, let source):
          self = .script(.appleScript(id: id, isEnabled: isEnabled,
                                      name: newValue, source: source))
        case .shell(let id, let isEnabled, _, let source):
          self = .script(.shell(id: id, isEnabled: isEnabled,
                                name: newValue, source: source))
        }
      case .type(var command):
        command.name = newValue
      }
    }
  }

  public var id: String {
    switch self {
    case .application(let command):
      return command.id
    case .builtIn(let command):
      return command.id
    case .keyboard(let command):
      return command.id
    case .open(let command):
      return command.id
    case .script(let command):
      return command.id
    case .type(let command):
      return command.id
    }
  }

  public var isEnabled: Bool {
    get {
      switch self {
      case .application(let applicationCommand):
        return applicationCommand.isEnabled
      case .builtIn(let builtInCommand):
        return builtInCommand.isEnabled
      case .keyboard(let keyboardCommand):
        return keyboardCommand.isEnabled
      case .open(let openCommand):
        return openCommand.isEnabled
      case .script(let scriptCommand):
        return scriptCommand.isEnabled
      case .type(let typeCommand):
        return typeCommand.isEnabled
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.isEnabled = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.isEnabled = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.isEnabled = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.isEnabled = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        scriptCommand.isEnabled = newValue
        self = .script(scriptCommand)
      case .type(var typeCommand):
        typeCommand.isEnabled = newValue
        self = .type(typeCommand)
      }
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    switch container.allKeys.first {
    case .application:
      let command = try container.decode(ApplicationCommand.self, forKey: .application)
      self = .application(command)
    case .builtIn:
      let command = try container.decode(BuiltInCommand.self, forKey: .builtIn)
      self = .builtIn(command)
    case .keyboard:
      let command = try container.decode(KeyboardCommand.self, forKey: .keyboard)
      self = .keyboard(command)
    case .open:
      let command = try container.decode(OpenCommand.self, forKey: .open)
      self = .open(command)
    case .script:
      let command = try container.decode(ScriptCommand.self, forKey: .script)
      self = .script(command)
    case .type:
      let command = try container.decode(TypeCommand.self, forKey: .type)
      self = .type(command)
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
    case .builtIn(let command):
      try container.encode(command, forKey: .builtIn)
    case .keyboard(let command):
      try container.encode(command, forKey: .keyboard)
    case .open(let command):
      try container.encode(command, forKey: .open)
    case .script(let command):
      try container.encode(command, forKey: .script)
    case .type(let command):
      try container.encode(command, forKey: .type)
    }
  }
}

public extension Command {
  static func empty(_ kind: CodingKeys) -> Command {
    switch kind {
    case .application:
      return Command.application(ApplicationCommand.empty())
    case .builtIn:
      return Command.builtIn(.init(kind: .quickRun))
    case .keyboard:
      return Command.keyboard(KeyboardCommand.empty())
    case .open:
      return Command.open(.init(path: ""))
    case .script:
      return Command.script(.appleScript(id: "", isEnabled: true,
                                         name: nil, source: .path("")))
    case .type:
      return Command.type(.init(name: "", input: ""))
    }
  }
}
