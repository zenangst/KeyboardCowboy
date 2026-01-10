import Foundation

public struct Rule: Identifiable, Codable, Hashable, Sendable {
  public var id: String
  public var allowedBundleIdentifiers: [String]
  public var disallowedBundleIdentifiers: [String]

  public init(id: String = UUID().uuidString,
              allowedBundleIdentifiers: [String] = [],
              disallowedBundleIdentifiers: [String] = []) {
    self.id = id
    self.allowedBundleIdentifiers = allowedBundleIdentifiers
    self.disallowedBundleIdentifiers = disallowedBundleIdentifiers
  }

  enum CodingKeys: String, CodingKey {
    case id
    case allowedBundleIdentifiers
    case bundleIdentifiers // Migration key
    case disallowedBundleIdentifiers
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

    // Migration of old bundleIdentifiers key
    if let allowed = try container.decodeIfPresent([String].self, forKey: .bundleIdentifiers) {
      allowedBundleIdentifiers = allowed
    } else {
      allowedBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .allowedBundleIdentifiers) ?? []
    }

    disallowedBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .disallowedBundleIdentifiers) ?? []
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)

    if !allowedBundleIdentifiers.isEmpty {
      try container.encode(allowedBundleIdentifiers, forKey: .allowedBundleIdentifiers)
    }

    if !disallowedBundleIdentifiers.isEmpty {
      try container.encode(disallowedBundleIdentifiers, forKey: .disallowedBundleIdentifiers)
    }
  }
}
