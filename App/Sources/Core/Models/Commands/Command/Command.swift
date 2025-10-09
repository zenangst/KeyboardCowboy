import Apps
import Foundation

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
    var delay: Double?
    var id: String
    var name: String
    var isEnabled: Bool
    var notification: Notification?
    var variableName: String?

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
         variableName: String? = nil)
    {
      self.delay = delay
      self.id = id
      self.name = name
      self.isEnabled = isEnabled
      self.notification = notification
      self.variableName = variableName
    }

    func copy() -> MetaData {
      MetaData(delay: delay,
               id: UUID().uuidString,
               name: name,
               isEnabled: isEnabled,
               notification: notification,
               variableName: variableName)
    }

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<Command.MetaData.CodingKeys> = try decoder.container(keyedBy: Command.MetaData.CodingKeys.self)
      delay = try container.decodeIfPresent(Double.self, forKey: Command.MetaData.CodingKeys.delay)
      id = try container.decode(String.self, forKey: Command.MetaData.CodingKeys.id)
      name = try container.decode(String.self, forKey: Command.MetaData.CodingKeys.name)
      isEnabled = try container.decode(Bool.self, forKey: Command.MetaData.CodingKeys.isEnabled)
      notification = try? container.decodeIfPresent(Command.Notification.self, forKey: Command.MetaData.CodingKeys.notification)
      variableName = try container.decodeIfPresent(String.self, forKey: Command.MetaData.CodingKeys.variableName)
    }
  }

  var meta: MetaData {
    get {
      switch self {
      case let .application(command): command.meta
      case let .builtIn(command): command.meta
      case let .bundled(command): command.meta
      case let .keyboard(command): command.meta
      case let .menuBar(command): command.meta
      case let .mouse(command): command.meta
      case let .open(command): command.meta
      case let .script(command): command.meta
      case let .shortcut(command): command.meta
      case let .systemCommand(command): command.meta
      case let .text(command): command.meta
      case let .uiElement(command): command.meta
      case let .windowFocus(command): command.meta
      case let .windowManagement(command): command.meta
      case let .windowTiling(command): command.meta
      }
    }
    set {
      switch self {
      case var .application(command):
        command.meta = newValue
        self = .application(command)
      case var .builtIn(command):
        command.meta = newValue
        self = .builtIn(command)
      case var .bundled(command):
        command.meta = newValue
        self = .bundled(command)
      case var .keyboard(command):
        command.meta = newValue
        self = .keyboard(command)
      case var .menuBar(command):
        command.meta = newValue
        self = .menuBar(command)
      case var .mouse(command):
        command.meta = newValue
        self = .mouse(command)
      case var .open(command):
        command.meta = newValue
        self = .open(command)
      case var .shortcut(command):
        command.meta = newValue
        self = .shortcut(command)
      case var .script(command):
        command.meta = newValue
        self = .script(command)
      case var .text(command):
        command.meta = newValue
        self = .text(command)
      case var .systemCommand(command):
        command.meta = newValue
        self = .systemCommand(command)
      case var .uiElement(command):
        command.meta = newValue
        self = .uiElement(command)
      case var .windowFocus(command):
        command.meta = newValue
        self = .windowFocus(command)
      case var .windowManagement(command):
        command.meta = newValue
        self = .windowManagement(command)
      case var .windowTiling(command):
        command.meta = newValue
        self = .windowTiling(command)
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
  case windowFocus(WindowFocusCommand)
  case windowManagement(WindowManagementCommand)
  case windowTiling(WindowTilingCommand)

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
    case windowFocus = "windowFocusCommand"
    case windowManagement = "windowManagementCommand"
    case windowTiling = "windowTilingCommand"
  }

  var isKeyboardBinding: Bool {
    switch self {
    case .keyboard:
      true
    default:
      false
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

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
    case .windowFocus:
      let command = try container.decode(WindowFocusCommand.self, forKey: .windowFocus)
      self = .windowFocus(command)
    case .windowManagement:
      let command = try container.decode(WindowManagementCommand.self, forKey: .windowManagement)
      self = .windowManagement(command)
    case .windowTiling:
      let command = try container.decode(WindowTilingCommand.self, forKey: .windowTiling)
      self = .windowTiling(command)
    case .none:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum.",
        ),
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .application(command): try container.encode(command, forKey: .application)
    case let .builtIn(command): try container.encode(command, forKey: .builtIn)
    case let .bundled(command): try container.encode(command, forKey: .bundled)
    case let .keyboard(command): try container.encode(command, forKey: .keyboard)
    case let .menuBar(command): try container.encode(command, forKey: .menuBar)
    case let .mouse(command): try container.encode(command, forKey: .mouse)
    case let .open(command): try container.encode(command, forKey: .open)
    case let .script(command): try container.encode(command, forKey: .script)
    case let .shortcut(command): try container.encode(command, forKey: .shortcut)
    case let .text(command): try container.encode(command, forKey: .text)
    case let .systemCommand(command): try container.encode(command, forKey: .system)
    case let .uiElement(command): try container.encode(command, forKey: .uiElement)
    case let .windowFocus(command): try container.encode(command, forKey: .windowFocus)
    case let .windowManagement(command): try container.encode(command, forKey: .windowManagement)
    case let .windowTiling(command): try container.encode(command, forKey: .windowTiling)
    }
  }

  func copy(appendCopyToName _: Bool = true) -> Self {
    let clone: Self = switch self {
    case let .application(command): .application(command.copy())
    case let .builtIn(command): .builtIn(command.copy())
    case let .bundled(command): .bundled(command.copy())
    case let .keyboard(command): .keyboard(command.copy())
    case let .mouse(command): .mouse(command.copy())
    case let .menuBar(command): .menuBar(command.copy())
    case let .open(command): .open(command.copy())
    case let .shortcut(command): .shortcut(command.copy())
    case let .script(command): .script(command.copy())
    case let .text(command): .text(command.copy())
    case let .systemCommand(command): .systemCommand(command.copy())
    case let .uiElement(command): .uiElement(command.copy())
    case let .windowFocus(command): .windowFocus(command.copy())
    case let .windowManagement(command): .windowManagement(command.copy())
    case let .windowTiling(command): .windowTiling(command.copy())
    }

    return clone
  }
}

extension Command {
  static func empty(_ kind: CodingKeys) -> Command {
    let id = UUID().uuidString
    let metaData = MetaData(id: id)
    return switch kind {
    case .application: Command.application(ApplicationCommand.empty())
    case .builtIn: Command.builtIn(.init(kind: .userMode(mode: .init(id: UUID().uuidString, name: "", isEnabled: true), action: .toggle), notification: nil))
    case .bundled: Command.bundled(.init(.workspace(command: WorkspaceCommand(applications: [], defaultForDynamicWorkspace: false, hideOtherApps: true, tiling: nil)), meta: metaData))
    case .keyboard: Command.keyboard(KeyboardCommand.empty())
    case .menuBar: Command.menuBar(MenuBarCommand(application: nil, tokens: []))
    case .mouse: Command.mouse(MouseCommand.empty())
    case .open: Command.open(.init(path: "", notification: nil))
    case .script: Command.script(.init(name: "", kind: .appleScript(variant: .regular), source: .path(""), notification: nil))
    case .shortcut: Command.shortcut(.init(id: id, shortcutIdentifier: "", name: "", isEnabled: true, notification: nil))
    case .text: Command.text(.init(.insertText(.init("", mode: .instant, meta: MetaData(id: id), actions: []))))
    case .system: Command.systemCommand(.init(id: UUID().uuidString, name: "", kind: .missionControl, notification: nil))
    case .uiElement: Command.uiElement(.init(meta: .init(), predicates: [.init(value: "")]))
    case .windowFocus: Command.windowFocus(.init(kind: .moveFocusToNextWindow, meta: metaData))
    case .windowManagement: Command.windowManagement(.init(id: UUID().uuidString, name: "", kind: .center, notification: nil, animationDuration: 0))
    case .windowTiling: Command.windowTiling(.init(kind: .arrangeLeftQuarters, meta: metaData))
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
      Command.builtIn(.init(kind: .userMode(mode: .init(id: id, name: "", isEnabled: true), action: .enable), notification: nil)),
    ]

    return result
  }

  static func applicationCommand(id: String) -> Command {
    Command.application(.init(id: id, application: Application.messages(name: "Application"), notification: nil))
  }

  static func appleScriptCommand(id: String) -> Command {
    Command.script(.init(id: id, name: "", kind: .appleScript(variant: .regular), source: .path(""), notification: nil))
  }

  static func shellScriptCommand(id: String) -> Command {
    Command.script(.init(id: id, name: "", kind: .shellScript, source: .path(""), notification: nil))
  }

  static func shortcutCommand(id: String) -> Command {
    Command.shortcut(ShortcutCommand(id: id, shortcutIdentifier: "Run shortcut",
                                     name: "Run shortcut", isEnabled: true, notification: nil))
  }

  static func keyboardCommand(id: String) -> Command {
    Command.keyboard(.init(id: id, name: "", kind: .key(command: .init(keyboardShortcuts: [], iterations: 1)), notification: nil))
  }

  static func openCommand(id: String) -> Command {
    Command.open(.init(id: id,
                       application: Application(
                         bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                         bundleName: "",
                         displayName: "",
                         path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                       ),
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
              notification: nil,
            ), actions: [],
          ),
        ),
      ),
    )
  }
}

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
