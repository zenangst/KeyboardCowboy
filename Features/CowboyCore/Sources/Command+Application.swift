import Apps
import Foundation

public extension Command {
  struct Application: MetaDataProviding {
    public var application: Apps::Application
    public var action: Action
    public var modifiers: Set<Modifier>
    public var meta: Metadata

    public init(id: String = UUID().uuidString,
                name: String = "",
                action: Action = .open,
                application: Apps::Application,
                modifiers: [Modifier] = [],
                notification: Command.Notification? = nil) {
      meta = Metadata(id: id, name: name, isEnabled: true, notification: notification)
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

    init(action: Action, application: Apps::Application,
         meta: Metadata, modifiers: [Modifier]) {
      self.application = application
      self.modifiers = Set(modifiers)
      self.meta = meta
      self.action = action
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      application = try container.decode(Apps::Application.self, forKey: .application)
      action = try container.decode(Command.Application.Action.self, forKey: .action)
      modifiers = try container.decodeIfPresent(Set<Command.Application.Modifier>.self, forKey: .modifiers) ?? []
      meta = try container.decode(Metadata.self, forKey: .meta)
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let sortedModifiers = modifiers.sorted(by: { $0.rawValue < $1.rawValue })

      try container.encode(application, forKey: .application)
      try container.encode(action, forKey: .action)
      if !sortedModifiers.isEmpty {
        try container.encode(sortedModifiers, forKey: .modifiers)
      }
      try container.encode(meta, forKey: .meta)
    }

    func copy() -> Command.Application {
      Command.Application(
        action: action,
        application: application,
        meta: meta.copy(),
        modifiers: Array(modifiers),
      )
    }
  }
}
