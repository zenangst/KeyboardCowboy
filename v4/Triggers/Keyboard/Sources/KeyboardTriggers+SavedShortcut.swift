public extension KeyboardTriggers {
  /// The matching fields in a v3 saved shortcut. The saved ID is not needed to match.
  struct SavedShortcut: Decodable, Sendable {
    public let key: String
    public let modifiers: [Modifier]

    public init(key: String, modifiers: [Modifier] = []) {
      self.key = key
      self.modifiers = modifiers
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      key = try container.decode(String.self, forKey: .key)
      modifiers = try container.decodeIfPresent([Modifier].self, forKey: .modifiers) ?? []
    }

    private enum CodingKeys: CodingKey { case key, modifiers }
  }
}
