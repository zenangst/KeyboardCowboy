import Foundation

struct SystemCommand: MetaDataProviding {
  var kind: Kind
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String, kind: Kind, 
       notification: Command.Notification? = nil) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
  }

  init(kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.kind = try container.decode(Kind.self, forKey: .kind)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  func copy() -> SystemCommand {
    SystemCommand(kind: kind, meta: meta.copy())
  }
}
