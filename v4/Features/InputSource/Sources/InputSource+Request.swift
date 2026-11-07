import Foundation
import InputSourceSystem

public extension InputSource {
  /// The nested input-source command, independent of the host's command metadata.
  struct Request: Codable, Hashable, Sendable {
    public let id: String
    public let inputSourceId: String
    public let name: String

    public init(id: String = UUID().uuidString, inputSourceId: String, name: String) {
      self.id = id
      self.inputSourceId = inputSourceId
      self.name = name
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      inputSourceId = try container.decode(String.self, forKey: .inputSourceId)
      name = try container.decodeIfPresent(String.self, forKey: .name) ?? inputSourceId
    }
  }
}
