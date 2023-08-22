import Foundation

struct TypeCommand: MetaDataProviding {
  enum Mode: String, Hashable, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case typing = "Typing"
    case instant = "Instant"
  }

  var input: String
  var mode: Mode = .instant
  var meta: Command.MetaData

  init(
    id: String = UUID().uuidString,
    name: String,
    mode: Mode,
    input: String,
    notification: Bool = false
  ) {
    self.input = input
    self.mode = mode
    self.meta = Command.MetaData(id: id, name: name,
                                 isEnabled: true,
                                 notification: notification)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.input = try container.decode(String.self, forKey: .input)
    self.mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .instant

    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }
}
