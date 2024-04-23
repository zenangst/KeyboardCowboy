import Apps
import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
struct ApplicationCommand: MetaDataProviding {
  enum Modifier: String, Codable, Hashable, CaseIterable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .background: return "Open in background"
      case .hidden: return "Hide when opening"
      case .onlyIfNotRunning: return "Open if not running"
      }
    }
    case background
    case hidden
    case onlyIfNotRunning
  }

  enum Action: String, Codable, Hashable, Equatable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .open:  "Open"
      case .close: "Close"
      case .hide:  "Hide"
      }
    }
    case open, close, hide
  }

  var application: Application
  var action: Action
  var modifiers: Set<Modifier>
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
       name: String = "",
       action: Action = .open,
       application: Application,
       modifiers: [Modifier] = [],
       notification: Bool = false) {
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.application = application
    self.modifiers = Set(modifiers)
    self.action = action
  }

  init(action: Action, application: Application,
       meta: Command.MetaData, modifiers: [Modifier]) {
    self.application = application
    self.modifiers = Set(modifiers)
    self.meta = meta
    self.action = action
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.application = try container.decode(Application.self, forKey: .application)
    self.action = try container.decode(ApplicationCommand.Action.self, forKey: .action)
    self.modifiers = try container.decode(Set<ApplicationCommand.Modifier>.self, forKey: .modifiers)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  func copy() -> ApplicationCommand {
    ApplicationCommand(
      action: self.action,
      application: self.application,
      meta: self.meta.copy(),
      modifiers: Array(self.modifiers)
    )
  }
}

extension ApplicationCommand {
  static func empty() -> ApplicationCommand {
    ApplicationCommand(action: .open,
                       application: Application(bundleIdentifier: "", bundleName: "", path: ""),
                       notification: false)
  }
}
