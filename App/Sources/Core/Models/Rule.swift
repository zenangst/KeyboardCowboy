import Foundation

public struct Rule: Identifiable, Codable, Hashable, Sendable {
  public var id: String
  public var bundleIdentifiers: [String]

  public init(id: String = UUID().uuidString, bundleIdentifiers: [String] = []) {
    self.id = id
    self.bundleIdentifiers = bundleIdentifiers
  }

  enum CodingKeys: String, CodingKey {
    case id
    case bundleIdentifiers
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.bundleIdentifiers = try container.decode([String].self, forKey: .bundleIdentifiers)
  }
}
