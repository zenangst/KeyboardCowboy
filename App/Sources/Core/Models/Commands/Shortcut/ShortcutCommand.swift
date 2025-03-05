import Foundation

struct ShortcutCommand: MetaDataProviding {
  let shortcutIdentifier: String
  var meta: Command.MetaData

  internal init(id: String, shortcutIdentifier: String, name: String, isEnabled: Bool, 
                notification: Command.Notification? = nil) {
    self.shortcutIdentifier = shortcutIdentifier
    self.meta = Command.MetaData(id: id, name: name, isEnabled: isEnabled, notification: notification)
  }

  init(shortcutIdentifier: String, meta: Command.MetaData) {
    self.shortcutIdentifier = shortcutIdentifier
    self.meta = meta
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.shortcutIdentifier = try container.decode(String.self, forKey: .shortcutIdentifier)
    self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
  }

  func copy() -> ShortcutCommand {
    ShortcutCommand(shortcutIdentifier: shortcutIdentifier, meta: meta.copy())
  }

  static func empty() -> ShortcutCommand {
    ShortcutCommand(id: UUID().uuidString,
                    shortcutIdentifier: "Shortcut", name: "Shortcut",
                    isEnabled: true, notification: nil)
  }
}
