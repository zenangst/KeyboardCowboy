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

  var notification: Command.Notification? {
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

  var variableName: String? {
    get { meta.variableName }
    set { 
      if newValue == nil || newValue?.isEmpty == true {
        meta.variableName = nil
      } else {
        meta.variableName = newValue
      }
    }
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
    let notification: Command.Notification?

    if let notificationValue = try container.decodeIfPresent(Command.Notification.self, forKey: .notification) {
      notification = notificationValue
    } else if let notificationBool = try container.decodeIfPresent(Bool.self, forKey: .notification) {
      if notificationBool {
        notification = .bezel
      } else {
        notification = nil
      }
    } else {
      notification = nil
    }

    let delay = try container.decodeIfPresent(Double.self, forKey: .delay)

    return Command.MetaData(delay: delay, id: id, name: name,
                            isEnabled: isEnabled, notification: notification)
  }
}


/// A `Command` is a polymorphic entity that is used
/// to store multiple command types in the same workflow.
/// All underlying data-types are both `Codable` and `Hashable`.
enum Command: MetaDataProviding, Identifiable, Equatable, Codable, Hashable, Sendable {
  enum Notification: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }
    case bezel
    case commandPanel
    case capsule
    var displayValue: String {
      switch self {
      case .bezel: "Bezel"
      case .commandPanel: "Command Panel"
      case .capsule: "Capsule UI"
      }
    }

    static var regularCases: [Notification] { [.bezel, .capsule] }
  }

  struct MetaData: Identifiable, Codable, Hashable, Sendable {
    public var delay: Double?
    public var id: String
    public var name: String
    public var isEnabled: Bool
    public var notification: Notification?
    public var variableName: String?

    enum CodingKeys: String, CodingKey {
      case delay
      case id
      case name
      case isEnabled = "enabled"
      case notification
      case variableName
    }

    init(delay: Double? = nil,
         id: String = UUID().uuidString,
         name: String = "",
         isEnabled: Bool = true,
         notification: Notification? = nil,
         variableName: String? = nil) {
      self.delay = delay
      self.id = id
      self.name = name
      self.isEnabled = isEnabled
      self.notification = notification
      self.variableName = variableName
    }

    func copy() -> MetaData {
      MetaData(delay: self.delay,
               id: UUID().uuidString,
               name: self.name,
               isEnabled: self.isEnabled,
               notification: self.notification,
               variableName: self.variableName)
    }

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<Command.MetaData.CodingKeys> = try decoder.container(keyedBy: Command.MetaData.CodingKeys.self)
      self.delay = try container.decodeIfPresent(Double.self, forKey: Command.MetaData.CodingKeys.delay)
      self.id = try container.decode(String.self, forKey: Command.MetaData.CodingKeys.id)
      self.name = try container.decode(String.self, forKey: Command.MetaData.CodingKeys.name)
      self.isEnabled = try container.decode(Bool.self, forKey: Command.MetaData.CodingKeys.isEnabled)

      if let notificationBool = try? container.decodeIfPresent(Bool.self, forKey: .notification) {
        if notificationBool {
          self.notification = .bezel
        } else {
          self.notification = nil
        }
      } else {
        self.notification = try? container.decodeIfPresent(Command.Notification.self, forKey: Command.MetaData.CodingKeys.notification)
      }

      self.variableName = try container.decodeIfPresent(String.self, forKey: Command.MetaData.CodingKeys.variableName)
    }
  }

  var meta: MetaData {
    get {
      switch self {
      case .application(let applicationCommand): applicationCommand.meta
      case .builtIn(let builtInCommand): builtInCommand.meta
      case .bundled(let bundledCommand): bundledCommand.meta
      case .keyboard(let keyboardCommand): keyboardCommand.meta
      case .menuBar(let menuBarCommand): menuBarCommand.meta
      case .mouse(let mouseCommand): mouseCommand.meta
      case .open(let openCommand): openCommand.meta
      case .script(let scriptCommand): scriptCommand.meta
      case .shortcut(let shortcutCommand): shortcutCommand.meta
      case .systemCommand(let systemCommand): systemCommand.meta
      case .text(let textCommand): textCommand.meta
      case .uiElement(let uiElementCommand): uiElementCommand.meta
      case .windowManagement(let windowCommand): windowCommand.meta
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
      case .bundled(var bundledCommand):
        bundledCommand.meta = newValue
        self = .bundled(bundledCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.meta = newValue
        self = .keyboard(keyboardCommand)
      case .menuBar(var menuBarCommand):
        menuBarCommand.meta = newValue
        self = .menuBar(menuBarCommand)
      case .mouse(var mouseCommand):
        mouseCommand.meta = newValue
        self = .mouse(mouseCommand)
      case .open(var openCommand):
        openCommand.meta = newValue
        self = .open(openCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.meta = newValue
        self = .shortcut(shortcutCommand)
      case .script(var scriptCommand):
        scriptCommand.meta = newValue
        self = .script(scriptCommand)
      case .text(var textCommand):
        textCommand.meta = newValue
        self = .text(textCommand)
      case .systemCommand(var systemCommand):
        systemCommand.meta = newValue
        self = .systemCommand(systemCommand)
      case .uiElement(var uiElementCommand):
        uiElementCommand.meta = newValue
        self = .uiElement(uiElementCommand)
      case .windowManagement(var windowCommand):
        windowCommand.meta = newValue
        self = .windowManagement(windowCommand)
      }
    }
  }

  case application(ApplicationCommand)
  case builtIn(BuiltInCommand)
  case bundled(BundledCommand)
  case keyboard(KeyboardCommand)
  case mouse(MouseCommand)
  case menuBar(MenuBarCommand)
  case open(OpenCommand)
  case shortcut(ShortcutCommand)
  case script(ScriptCommand)
  case text(TextCommand)
  case systemCommand(SystemCommand)
  case uiElement(UIElementCommand)
  case windowManagement(WindowCommand)

  enum MigrationKeys: String, CodingKey, CaseIterable {
    case type = "typeCommand"
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case application = "applicationCommand"
    case builtIn = "builtInCommand"
    case bundled = "bundledCommand"
    case keyboard = "keyboardCommand"
    case menuBar = "menuBarCommand"
    case mouse = "mouseCommand"
    case open = "openCommand"
    case shortcut = "runShortcut"
    case script = "scriptCommand"
    case text = "textCommand"
    case system = "systemCommand"
    case uiElement = "uiElementCommand"
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
    let migration = try decoder.container(keyedBy: MigrationKeys.self)

    switch migration.allKeys.first {
    case .type:
      if let command = try? migration.decode(TextCommand.TypeCommand.self, forKey: .type) {
        self = .text(.init(.insertText(command)))
        return
      }
    case .none: break
    }

    switch container.allKeys.first {
    case .application:
      let command = try container.decode(ApplicationCommand.self, forKey: .application)
      self = .application(command)
    case .bundled:
      let command = try container.decode(BundledCommand.self, forKey: .bundled)
      self = .bundled(command)
    case .builtIn:
      let command = try container.decode(BuiltInCommand.self, forKey: .builtIn)
      self = .builtIn(command)
    case .keyboard:
      let command = try container.decode(KeyboardCommand.self, forKey: .keyboard)
      self = .keyboard(command)
    case .menuBar:
      let command = try container.decode(MenuBarCommand.self, forKey: .menuBar)
      self = .menuBar(command)
    case .mouse:
      let command = try container.decode(MouseCommand.self, forKey: .mouse)
      self = .mouse(command)
    case .open:
      let command = try container.decode(OpenCommand.self, forKey: .open)
      self = .open(command)
    case .script:
      let command = try container.decode(ScriptCommand.self, forKey: .script)
      self = .script(command)
    case .shortcut:
      let command = try container.decode(ShortcutCommand.self, forKey: .shortcut)
      self = .shortcut(command)
    case .text:
      let command = try container.decode(TextCommand.self, forKey: .text)
      self = .text(command)
    case .system:
      let command = try container.decode(SystemCommand.self, forKey: .system)
      self = .systemCommand(command)
    case .uiElement:
      let command = try container.decode(UIElementCommand.self, forKey: .uiElement)
      self = .uiElement(command)
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
    case .application(let command): try container.encode(command, forKey: .application)
    case .builtIn(let command): try container.encode(command, forKey: .builtIn)
    case .bundled(let command): try container.encode(command, forKey: .bundled)
    case .keyboard(let command): try container.encode(command, forKey: .keyboard)
    case .menuBar(let command): try container.encode(command, forKey: .menuBar)
    case .mouse(let command): try container.encode(command, forKey: .mouse)
    case .open(let command): try container.encode(command, forKey: .open)
    case .script(let command): try container.encode(command, forKey: .script)
    case .shortcut(let command): try container.encode(command, forKey: .shortcut)
    case .text(let command): try container.encode(command, forKey: .text)
    case .systemCommand(let command): try container.encode(command, forKey: .system)
    case .uiElement(let command): try container.encode(command, forKey: .uiElement)
    case .windowManagement(let command): try container.encode(command, forKey: .window)
    }
  }

  func copy(appendCopyToName: Bool = true) -> Self {
    let clone: Self = switch self {
    case .application(let applicationCommand): .application(applicationCommand.copy())
    case .builtIn(let builtInCommand): .builtIn(builtInCommand.copy())
    case .bundled(let bundledCommand): .bundled(bundledCommand.copy())
    case .keyboard(let keyboardCommand): .keyboard(keyboardCommand.copy())
    case .mouse(let mouseCommand): .mouse(mouseCommand.copy())
    case .menuBar(let menuBarCommand): .menuBar(menuBarCommand.copy())
    case .open(let openCommand): .open(openCommand.copy())
    case .shortcut(let shortcutCommand): .shortcut(shortcutCommand.copy())
    case .script(let scriptCommand): .script(scriptCommand.copy())
    case .text(let textCommand): .text(textCommand.copy())
    case .systemCommand(let systemCommand): .systemCommand(systemCommand.copy())
    case .uiElement(let uIElementCommand): .uiElement(uIElementCommand.copy())
    case .windowManagement(let windowCommand): .windowManagement(windowCommand.copy())
    }

    return clone
  }
}

extension Command {
  static func empty(_ kind: CodingKeys) -> Command {
    let id = UUID().uuidString
    return switch kind {
    case .application: Command.application(ApplicationCommand.empty())
    case .builtIn: Command.builtIn(.init(kind: .userMode(.init(id: UUID().uuidString, name: "", isEnabled: true), .toggle), notification: nil))
    case .bundled: Command.bundled(.init(.workspace(WorkspaceCommand(bundleIdentifiers: [], hideOtherApps: true, tiling: nil)), meta: Command.MetaData()))
    case .keyboard: Command.keyboard(KeyboardCommand.empty())
    case .menuBar: Command.menuBar(MenuBarCommand(application: nil, tokens: []))
    case .mouse: Command.mouse(MouseCommand.empty())
    case .open: Command.open(.init(path: "", notification: nil))
    case .script: Command.script(.init(name: "", kind: .appleScript, source: .path(""), notification: nil))
    case .shortcut: Command.shortcut(.init(id: id, shortcutIdentifier: "", name: "", isEnabled: true, notification: nil))
    case .text: Command.text(.init(.insertText(.init("", mode: .instant, meta: MetaData(id: id), actions: []))))
    case .system: Command.systemCommand(.init(id: UUID().uuidString, name: "", kind: .missionControl, notification: nil))
    case .uiElement: Command.uiElement(.init(meta: .init(), predicates: [.init(value: "")]))
    case .window: Command.windowManagement(.init(id: UUID().uuidString, name: "", kind: .center, notification: nil, animationDuration: 0))
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
      textCommand(id: id),
      Command.builtIn(.init(kind: .userMode(.init(id: id, name: "", isEnabled: true), .enable), notification: nil))
    ]

    return result
  }

  static func applicationCommand(id: String) -> Command {
    Command.application(.init(id: id, application: Application.messages(name: "Application"), notification: nil))
  }

  static func appleScriptCommand(id: String) -> Command {
    Command.script(.init(id: id, name: "", kind: .appleScript, source: .path(""), notification: nil))
  }

  static func shellScriptCommand(id: String) -> Command {
    Command.script(.init(id: id, name: "", kind: .shellScript, source: .path(""), notification: nil))
  }

  static func shortcutCommand(id: String) -> Command {
    Command.shortcut(ShortcutCommand(id: id, shortcutIdentifier: "Run shortcut",
                                     name: "Run shortcut", isEnabled: true, notification: nil))
  }

  static func keyboardCommand(id: String) -> Command {
    Command.keyboard(.init(id: id, name: "", isEnabled: true, keyboardShortcut: KeyShortcut.empty(), notification: nil))
  }

  static func openCommand(id: String) -> Command {
    Command.open(.init(id: id,
                       application: Application(
                        bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                        bundleName: "",
                        path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"),
                       path: "~/Developer/Xcode.project",
                       notification: nil))
  }

  static func urlCommand(id: String, application: Application?) -> Command {
    Command.open(.init(id: id,
                       application: application,
                       path: "https://github.com",
                       notification: nil))
  }

  static func textCommand(id: String) -> Command {
    Command.text(
      .init(
        .insertText(
          .init(
            "Insert input",
            mode: .instant,
            meta: .init(
              id: id,
              name: "",
              isEnabled: true,
              notification: nil
            ), actions: []
          )
        )
      )
    )
  }
}
