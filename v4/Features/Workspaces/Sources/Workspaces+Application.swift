public extension Workspaces {
  struct Application: Codable, Hashable, Sendable {
    public let bundleIdentifier: String
    public let onlyWhenRunning: Bool

    public init(_ bundleIdentifier: String, onlyWhenRunning: Bool = false) {
      self.bundleIdentifier = bundleIdentifier
      self.onlyWhenRunning = onlyWhenRunning
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
      let options = try? container.decodeIfPresent([Option].self, forKey: .options)
      onlyWhenRunning = options?.contains(.onlyWhenRunning) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
      if onlyWhenRunning { try container.encode([Option.onlyWhenRunning], forKey: .options) }
    }

    private enum CodingKeys: CodingKey { case bundleIdentifier, options }
    private enum Option: String, Codable { case onlyWhenRunning }
  }
}
