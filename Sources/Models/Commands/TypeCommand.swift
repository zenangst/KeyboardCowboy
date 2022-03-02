import Foundation

public struct TypeCommand: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public var name: String
  public var input: String
  public var isEnabled: Bool = true

  public init(id: String = UUID().uuidString,
              name: String,
              input: String) {
    self.id = id
    self.name = name
    self.input = input
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decode(String.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.input = try container.decode(String.self, forKey: .input)
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
  }
}
