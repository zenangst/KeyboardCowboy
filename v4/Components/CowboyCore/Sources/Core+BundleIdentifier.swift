public extension Core {
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

    public enum WildCard: String, Codable, Sendable, CaseIterable {
      case any = "*.*.*"
      case current = "*.*.current"
      case previous = "*.*.previous"

      public var bundleIdentifier: BundleIdentifier {
        BundleIdentifier(rawValue)
      }

      public static func == (lhs: WildCard, rhs: BundleIdentifier) -> Bool {
        lhs.bundleIdentifier == rhs
      }

      public static func == (lhs: BundleIdentifier, rhs: WildCard) -> Bool {
        lhs == rhs.bundleIdentifier
      }
    }
  }
}
