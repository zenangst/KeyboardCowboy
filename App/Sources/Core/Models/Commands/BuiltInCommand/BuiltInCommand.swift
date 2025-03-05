import Foundation

struct BuiltInCommand: MetaDataProviding {
  var meta: Command.MetaData
  let kind: Kind

  enum MigrationCodingKeys: String, CodingKey {
    case id, kind
    case isEnabled = "enabled"
    case notification
  }

  init(id: String = UUID().uuidString, kind: Kind, notification: Command.Notification?) {
    self.kind = kind
    self.meta = .init(id: id, name: kind.displayValue, isEnabled: true, notification: notification)
  }

  init(kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
    self.kind = try container.decode(BuiltInCommand.Kind.self, forKey: .kind)
  }

  func copy() -> BuiltInCommand {
    BuiltInCommand(kind: self.kind, meta: self.meta.copy())
  }
}
