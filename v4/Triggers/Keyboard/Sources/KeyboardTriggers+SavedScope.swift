public extension KeyboardTriggers {
  /// The app-scoping fields of a saved v3 workflow group rule.
  struct SavedScope: Decodable, Sendable {
    public let allowedBundleIdentifiers: Set<String>
    public let disallowedBundleIdentifiers: Set<String>

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      allowedBundleIdentifiers = try container.decodeIfPresent(Set<String>.self, forKey: .bundleIdentifiers)
        ?? container.decodeIfPresent(Set<String>.self, forKey: .allowedBundleIdentifiers)
        ?? []
      disallowedBundleIdentifiers = try container.decodeIfPresent(Set<String>.self, forKey: .disallowedBundleIdentifiers) ?? []
    }

    private enum CodingKeys: CodingKey {
      case bundleIdentifiers, allowedBundleIdentifiers, disallowedBundleIdentifiers
    }
  }
}
