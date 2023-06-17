import Foundation

struct TypeCommand: MetaDataProviding {
  var input: String
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String,
       input: String, notification: Bool = false) {
    self.input = input
    self.meta = Command.MetaData(id: id, name: name,
                                 isEnabled: true,
                                 notification: notification)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.input = try container.decode(String.self, forKey: .input)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }
}
