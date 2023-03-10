import Apps
import Foundation

/// A `Command` is a polymorphic entity that is used
/// to store multiple command types in the same workflow.
/// All underlying data-types are both `Codable` and `Hashable`.
public enum Command: Identifiable, Equatable, Codable, Hashable, Sendable {
  case application(ApplicationCommand)
  case builtIn(BuiltInCommand)
  case keyboard(KeyboardCommand)
  case open(OpenCommand)
  case shortcut(ShortcutCommand)
  case script(ScriptCommand)
  case type(TypeCommand)

  public enum CodingKeys: String, CodingKey, CaseIterable {
    case application = "applicationCommand"
    case builtIn = "builtInCommand"
    case keyboard = "keyboardCommand"
    case open = "openCommand"
    case shortcut = "runShortcut"
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
        var keyboardShortcutString: String = ""
        command.keyboardShortcuts.forEach { keyboardShortcut in
          keyboardShortcutString += keyboardShortcut.modifiers.map(\.pretty).joined()
          keyboardShortcutString += keyboardShortcut.key
        }

        return command.name.isEmpty ? "Run a Keyboard Shortcut: \(keyboardShortcutString)" : command.name
      case .open(let command):
        if !command.name.isEmpty { return command.name }
        if command.isUrl {
          return "Open a URL: \(command.path)"
        } else {
          return "Open a file: \(command.path)"
        }
      case .shortcut(let command):
        return "Run '\(command.shortcutIdentifier)'"
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
        self = .application(command)
      case .builtIn:
        break
      case .keyboard(var command):
        command.name = newValue
        self = .keyboard(command)
      case .open(var command):
        command.name = newValue
        self = .open(command)
      case .script(let command):
        switch command {
        case .appleScript(let id, let isEnabled, _, let source):
          self = .script(.appleScript(id: id, isEnabled: isEnabled,
                                      name: newValue, source: source))
        case .shell(let id, let isEnabled, _, let source):
          self = .script(.shell(id: id, isEnabled: isEnabled,
                                name: newValue, source: source))
        }
      case .shortcut(var command):
        command.name = newValue
        self = .shortcut(command)
      case .type(var command):
        command.name = newValue
        self = .type(command)
      }
    }
  }

  public var id: String {
    get {
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
      case .shortcut(let command):
        return command.id
      case .type(let command):
        return command.id
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.id = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.id = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.id = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.id = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        scriptCommand.id = newValue
        self = .script(scriptCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.id = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.id = newValue
        self = .type(typeCommand)
      }
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
      case .shortcut(let shortcutCommand):
        return shortcutCommand.isEnabled
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
      case .shortcut(var shortcutCommand):
        shortcutCommand.isEnabled = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.isEnabled = newValue
        self = .type(typeCommand)
      }
    }
  }

  public var notification: Bool {
    get {
      switch self {
      case .application(let applicationCommand):
        return applicationCommand.notification
      case .builtIn(let builtInCommand):
        return builtInCommand.notification
      case .keyboard(let keyboardCommand):
        return keyboardCommand.notification
      case .open(let openCommand):
        return openCommand.notification
      case .script(let scriptCommand):
        // TODO: Add support for `.notification` on script commands.
        return false
//        return scriptCommand.notification
      case .shortcut(let shortcutCommand):
        return shortcutCommand.notification
      case .type(let typeCommand):
        return typeCommand.notification
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.notification = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.notification = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.notification = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.notification = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        // TODO: Add support for notification on script command
//        scriptCommand.notification = newValue
        self = .script(scriptCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.notification = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.notification = newValue
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
    case .shortcut:
      let command = try container.decode(ShortcutCommand.self, forKey: .shortcut)
      self = .shortcut(command)
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
    case .shortcut(let command):
      try container.encode(command, forKey: .shortcut)
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
      return Command.builtIn(.init(kind: .quickRun, notification: false))
    case .keyboard:
      return Command.keyboard(KeyboardCommand.empty())
    case .open:
      return Command.open(.init(path: "", notification: false))
    case .script:
      return Command.script(.appleScript(id: UUID().uuidString, isEnabled: true,
                                         name: nil, source: .path("")))
    case .shortcut:
      return Command.shortcut(.init(id: UUID().uuidString, shortcutIdentifier: "",
                                    name: "", isEnabled: true, notification: false))
    case .type:
      return Command.type(.init(name: "", input: "", notification: false))
    }
  }

  static func commands(id: String = UUID().uuidString) -> [Command] {
    let result = [
      applicationCommand(id: id),
      appleScriptCommand(id: id),
      shellScriptCommand(id: id),
      keyboardCommand(id: id),
      openCommand(id: id),
      urlCommand(id: id, application: nil),
      typeCommand(id: id),
      Command.builtIn(.init(kind: .quickRun, notification: false))
    ]

    return result
  }

  static func applicationCommand(id: String) -> Command {
    Command.application(.init(id: id, application: Application.messages(name: "Application"), notification: false))
  }

  static func appleScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.appleScript, id: id))
  }

  static func shellScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.shell, id: id))
  }

  static func shortcutCommand(id: String) -> Command {
    Command.shortcut(ShortcutCommand(id: id, shortcutIdentifier: "Run shortcut",
                                     name: "Run shortcut", isEnabled: true, notification: false))
  }

  static func keyboardCommand(id: String) -> Command {
    Command.keyboard(.init(id: id, keyboardShortcut: KeyShortcut.empty(), notification: false))
  }

  static func openCommand(id: String) -> Command {
    Command.open(.init(id: id,
                       application: Application(
                        bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                        bundleName: "",
                        path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"),
                       path: "~/Developer/Xcode.project",
                       notification: false))
  }

  static func urlCommand(id: String, application: Application?) -> Command {
    Command.open(.init(id: id,
                       application: application,
                       path: "https://github.com",
                       notification: false))
  }

  static func typeCommand(id: String) -> Command {
    Command.type(.init(id: id, name: "Type input", input: "", notification: false))
  }
}
