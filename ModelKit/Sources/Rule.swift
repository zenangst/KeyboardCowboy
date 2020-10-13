import Foundation

public struct Rule: Identifiable, Codable, Hashable {
  public var id: String
  public var bundleIdentifiers: [String]
  public var days: [Day]

  public init(id: String = UUID().uuidString, bundleIdentifiers: [String] = [], days: [Day] = []) {
    self.id = id
    self.bundleIdentifiers = bundleIdentifiers
    self.days = days
  }

  enum CodingKeys: String, CodingKey {
    case id
    case bundleIdentifiers
    case days
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.bundleIdentifiers = try container.decode([String].self, forKey: .bundleIdentifiers)
    self.days = try container.decode([Day].self, forKey: .days)
  }

  public enum Day: Int, Codable, Hashable {
    case monday = 0
    case tuesday = 1
    case wednesday = 2
    case thursday = 3
    case friday = 4
    case saturday = 5
    case sunday = 6
  }
}
