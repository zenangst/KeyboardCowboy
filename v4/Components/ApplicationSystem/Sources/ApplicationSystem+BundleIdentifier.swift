public extension ApplicationSystem {
  struct BundleIdentifier: Hashable, Identifiable, Equatable, Codable, Sendable, CustomStringConvertible {
    public var id: String { value }
    public let value: String
    public var description: String { String(value) }

    public init(_ value: String) {
      self.value = value
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.value = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(value)
    }
  }
}
