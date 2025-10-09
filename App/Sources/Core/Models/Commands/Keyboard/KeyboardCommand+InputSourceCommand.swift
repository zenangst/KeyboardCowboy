import Foundation

extension KeyboardCommand {
  struct InputSourceCommand: Codable, Hashable {
    let id: String
    let name: String
    let inputSourceId: String

    init(id: String = UUID().uuidString, inputSourceId: String, name: String) {
      self.id = id
      self.inputSourceId = inputSourceId
      self.name = name
    }

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<KeyboardCommand.InputSourceCommand.CodingKeys> = try decoder.container(keyedBy: KeyboardCommand.InputSourceCommand.CodingKeys.self)
      id = try container.decode(String.self, forKey: KeyboardCommand.InputSourceCommand.CodingKeys.id)
      let inputSourceId = try container.decode(String.self, forKey: KeyboardCommand.InputSourceCommand.CodingKeys.inputSourceId)
      self.inputSourceId = inputSourceId
      name = try container.decodeIfPresent(String.self, forKey: KeyboardCommand.InputSourceCommand.CodingKeys.name) ?? inputSourceId
    }
  }
}
