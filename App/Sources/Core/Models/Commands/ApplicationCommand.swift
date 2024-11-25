import Apps
import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
struct ApplicationCommand: MetaDataProviding {
  enum Modifier: String, Codable, Hashable, CaseIterable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .background: "Open in background"
      case .hidden: "Hide when opening"
      case .onlyIfNotRunning: "Open if not running"
      case .addToStage: "Add to current stage"
      case .waitForAppToLaunch: "Wait for app to launch"
      }
    }
    case background
    case hidden
    case onlyIfNotRunning
    case addToStage
    case waitForAppToLaunch
  }

  enum Action: String, Codable, Hashable, Equatable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .open:  "Open"
      case .close: "Close"
      case .hide:  "Hide"
      case .unhide: "Unhide"
      case .peek: "Peek"
      }
    }
    case open, close, hide, unhide, peek
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
       notification: Command.Notification? = nil) {
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.application = application
    self.modifiers = Set(modifiers)
    self.action = action
  }

  enum CodingKeys: CodingKey {
    case application
    case action
    case modifiers
    case meta
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
    self.modifiers = try container.decodeIfPresent(Set<ApplicationCommand.Modifier>.self, forKey: .modifiers) ?? []
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let sortedModifiers = self.modifiers.sorted(by: { $0.rawValue < $1.rawValue  })

    try container.encode(self.application, forKey: .application)
    try container.encode(self.action, forKey: .action)
    if !sortedModifiers.isEmpty {
      try container.encode(sortedModifiers, forKey: .modifiers)
    }
    try container.encode(self.meta, forKey: .meta)
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
                       notification: nil)
  }
}
