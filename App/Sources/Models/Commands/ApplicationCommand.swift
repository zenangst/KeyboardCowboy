import Apps
import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
public struct ApplicationCommand: Identifiable, Codable, Hashable, Sendable {
  public enum Modifier: String, Toggleable, Codable, Hashable, CaseIterable, Sendable {
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

  public enum Action: String, Codable, Hashable, Equatable, Toggleable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .open: return "Open"
      case .close: return "Close"
      }
    }
    case open, close
  }

  public var id: String
  public var name: String
  public var application: Application
  public var action: Action
  public var modifiers: Set<Modifier>
  public var isEnabled: Bool = true
  public var notification: Bool

  public init(id: String = UUID().uuidString, name: String = "",
              action: Action = .open,
              application: Application,
              modifiers: [Modifier] = [],
              notification: Bool = false) {
    self.id = id
    self.name = name
    self.application = application
    self.modifiers = Set(modifiers)
    self.action = action
    self.notification = notification
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case action
    case application
    case modifiers
    case isEnabled = "enabled"
    case notification
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    self.action = try container.decodeIfPresent(Action.self, forKey: .action) ?? .open
    self.application = try container.decode(Application.self, forKey: .application)
    self.modifiers = try container.decodeIfPresent(Set<Modifier>.self, forKey: .modifiers) ?? []
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    self.notification = try container.decodeIfPresent(Bool.self, forKey: .notification) ?? false
  }
}

public extension ApplicationCommand {
  static func empty() -> ApplicationCommand {
    ApplicationCommand(action: .open,
                       application: Application(bundleIdentifier: "", bundleName: "", path: ""),
                       notification: false)
  }
}
