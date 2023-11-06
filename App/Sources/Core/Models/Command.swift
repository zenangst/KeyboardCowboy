import Apps
import Foundation

protocol MetaDataProviding: Identifiable, Codable, Hashable, Sendable {
  var meta: Command.MetaData { get set }
}

extension MetaDataProviding {
  var id: String {
    get { meta.id }
    set { meta.id = newValue }
  }

  var name: String {
    get { meta.name }
    set { meta.name = newValue }
  }

  var notification: Bool {
    get { meta.notification }
    set { meta.notification = newValue }
  }

  var isEnabled: Bool {
    get { meta.isEnabled }
    set { meta.isEnabled = newValue }
  }

  var delay: Double? {
    get { meta.delay }
    set { meta.delay = newValue }
  }

}

enum MetaDataMigrator: String, CodingKey {
  case id
  case name
  case isEnabled = "enabled"
  case notification

  static func migrate(_ decoder: Decoder) throws -> Command.MetaData {
    Task {
      await MainActor.run {
        Migration.shouldSave = true
      }
    }
    // Try and migrate from the previous data structure.
    let container = try decoder.container(keyedBy: Command.MetaData.CodingKeys.self)
    let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    let notification = try container.decodeIfPresent(Bool.self, forKey: .notification) ?? false
    let delay = try container.decodeIfPresent(Double.self, forKey: .delay)
    return Command.MetaData(delay: delay, id: id, name: name,
                            isEnabled: isEnabled, notification: notification)
  }
}


/// A `Command` is a polymorphic entity that is used
/// to store multiple command types in the same workflow.
/// All underlying data-types are both `Codable` and `Hashable`.
enum Command: MetaDataProviding, Identifiable, Equatable, Codable, Hashable, Sendable {
  struct MetaData: Identifiable, Codable, Hashable, Sendable {
    public var delay: Double?
    public var id: String
    public var name: String
    public var isEnabled: Bool
    public var notification: Bool

    enum CodingKeys: String, CodingKey {
      case delay
      case id
      case name
      case isEnabled = "enabled"
      case notification
    }
  }

  var meta: MetaData {
    get {
      switch self {
      case .application(let applicationCommand):
        return applicationCommand.meta
      case .builtIn(let builtInCommand):
        return builtInCommand.meta
      case .keyboard(let keyboardCommand):
        return keyboardCommand.meta
      case .menuBar(let menuBarCommand):
        return menuBarCommand.meta
      case .open(let openCommand):
        return openCommand.meta
      case .shortcut(let shortcutCommand):
        return shortcutCommand.meta
      case .script(let scriptCommand):
        return scriptCommand.meta
      case .type(let typeCommand):
        return typeCommand.meta
      case .systemCommand(let systemCommand):
        return systemCommand.meta
      case .windowManagement(let windowCommand):
        return windowCommand.meta
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.meta = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.meta = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.meta = newValue
        self = .keyboard(keyboardCommand)
      case .menuBar(var menuBarCommand):
        menuBarCommand.meta = newValue
        self = .menuBar(menuBarCommand)
      case .open(var openCommand):
        openCommand.meta = newValue
        self = .open(openCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.meta = newValue
        self = .shortcut(shortcutCommand)
      case .script(var scriptCommand):
        scriptCommand.meta = newValue
        self = .script(scriptCommand)
      case .type(var typeCommand):
        typeCommand.meta = newValue
        self = .type(typeCommand)
      case .systemCommand(var systemCommand):
        systemCommand.meta = newValue
        self = .systemCommand(systemCommand)
      case .windowManagement(var windowCommand):
        windowCommand.meta = newValue
        self = .windowManagement(windowCommand)
      }
    }
  }

  case application(ApplicationCommand)
  case builtIn(BuiltInCommand)
  case keyboard(KeyboardCommand)
  case menuBar(MenuBarCommand)
  case open(OpenCommand)
  case shortcut(ShortcutCommand)
  case script(ScriptCommand)
  case type(TypeCommand)
  case systemCommand(SystemCommand)
  case windowManagement(WindowCommand)

  enum CodingKeys: String, CodingKey, CaseIterable {
    case application = "applicationCommand"
    case builtIn = "builtInCommand"
    case keyboard = "keyboardCommand"
    case menuBar = "menuBarCommand"
    case open = "openCommand"
    case shortcut = "runShortcut"
    case script = "scriptCommand"
    case type = "typeCommand"
    case system = "systemCommand"
    case window = "windowCommand"
  }

  var isKeyboardBinding: Bool {
    switch self {
    case .keyboard:
      return true
    default:
      return false
    }
  }

  init(from decoder: Decoder) throws {
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
    case .menuBar:
      let command = try container.decode(MenuBarCommand.self, forKey: .menuBar)
      self = .menuBar(command)
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
    case .system:
      let command = try container.decode(SystemCommand.self, forKey: .system)
      self = .systemCommand(command)
    case .window:
      let command = try container.decode(WindowCommand.self, forKey: .window)
      self = .windowManagement(command)
    case .none:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .application(let command):
      try container.encode(command, forKey: .application)
    case .builtIn(let command):
      try container.encode(command, forKey: .builtIn)
    case .keyboard(let command):
      try container.encode(command, forKey: .keyboard)
    case .menuBar(let command):
      try container.encode(command, forKey: .menuBar)
    case .open(let command):
      try container.encode(command, forKey: .open)
    case .script(let command):
      try container.encode(command, forKey: .script)
    case .shortcut(let command):
      try container.encode(command, forKey: .shortcut)
    case .type(let command):
      try container.encode(command, forKey: .type)
    case .systemCommand(let command):
      try container.encode(command, forKey: .system)
    case .windowManagement(let command):
      try container.encode(command, forKey: .window)
    }
  }

  func copy(appendCopyToName: Bool = true) -> Self {
    var clone = self
    clone.id = UUID().uuidString
    return clone
  }
}

extension Command {
  static func empty(_ kind: CodingKeys) -> Command {
    switch kind {
    case .application:
      return Command.application(ApplicationCommand.empty())
    case .builtIn:
      return Command.builtIn(.init(kind: .quickRun, notification: false))
    case .keyboard:
      return Command.keyboard(KeyboardCommand.empty())
    case .menuBar:
      return Command.menuBar(MenuBarCommand(tokens: []))
    case .open:
      return Command.open(.init(path: "", notification: false))
    case .script:
      return Command.script(.init(name: "", kind: .appleScript, source: .path(""), notification: false))
    case .shortcut:
      return Command.shortcut(.init(id: UUID().uuidString, shortcutIdentifier: "",
                                    name: "", isEnabled: true, notification: false))
    case .type:
      return Command.type(.init(name: "", mode: .instant, input: "", notification: false))
    case .system:
      return Command.systemCommand(.init(id: UUID().uuidString, name: "", kind: .missionControl, notification: false))
    case .window:
      return Command.windowManagement(.init(id: UUID().uuidString, name: "", kind: .center, notification: false, animationDuration: 0))
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
    Command.script(.init(id: id, name: "", kind: .appleScript, source: .path(""), notification: false))
  }

  static func shellScriptCommand(id: String) -> Command {
    Command.script(.init(id: id, name: "", kind: .shellScript, source: .path(""), notification: false))
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
    Command.type(.init(id: id, name: "Type input", mode: .instant,
                       input: "", notification: false))
  }
}
