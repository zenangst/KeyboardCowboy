import Foundation

struct ShortcutCommand: MetaDataProviding {
  let shortcutIdentifier: String
  var meta: Command.MetaData

  internal init(id: String, shortcutIdentifier: String, name: String, isEnabled: Bool, notification: Bool) {
    self.shortcutIdentifier = shortcutIdentifier
    self.meta = Command.MetaData(id: id, name: name, isEnabled: isEnabled, notification: notification)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.shortcutIdentifier = try container.decode(String.self, forKey: .shortcutIdentifier)

    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  static func empty() -> ShortcutCommand {
    ShortcutCommand(id: UUID().uuidString,
                    shortcutIdentifier: "Shortcut", name: "Shortcut",
                    isEnabled: true, notification: false)
  }
}
