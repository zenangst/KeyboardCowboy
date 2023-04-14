import Foundation

public struct ShortcutCommand: Identifiable, Codable, Hashable, Sendable {
  public var id: String
  public let shortcutIdentifier: String

  public var name: String
  public var isEnabled: Bool
  public var notification: Bool
  
  internal init(id: String, shortcutIdentifier: String, name: String, isEnabled: Bool, notification: Bool) {
    self.id = id
    self.shortcutIdentifier = shortcutIdentifier
    self.name = name
    self.isEnabled = isEnabled
    self.notification = notification
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.shortcutIdentifier = try container.decode(String.self, forKey: .shortcutIdentifier)
    self.name = try container.decode(String.self, forKey: .name)
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    self.notification = try container.decodeIfPresent(Bool.self, forKey: .notification) ?? false
  }

  static func empty() -> ShortcutCommand {
    ShortcutCommand(id: UUID().uuidString,
                    shortcutIdentifier: "Shortcut", name: "Shortcut",
                    isEnabled: true, notification: false)
  }
}
