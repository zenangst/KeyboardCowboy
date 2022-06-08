import Foundation

public struct ShortcutCommand: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public let shortcutIdentifier: String

  public var name: String
  public var isEnabled: Bool

  static func empty() -> ShortcutCommand {
    ShortcutCommand(id: UUID().uuidString,
                    shortcutIdentifier: "Shortcut", name: "Shortcut",
                    isEnabled: true)
  }
}
