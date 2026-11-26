public extension ApplicationSystem.BundleIdentifier {
  enum WildCard: String, Codable, Sendable, CaseIterable {
    case any = "*.*.*"
    case current = "*.*.current"
    case previous = "*.*.previous"

    public var bundleIdentifier: ApplicationSystem.BundleIdentifier {
      ApplicationSystem.BundleIdentifier(rawValue)
    }

    public static func == (lhs: WildCard, rhs: ApplicationSystem.BundleIdentifier) -> Bool {
      lhs.bundleIdentifier == rhs
    }

    public static func == (lhs: ApplicationSystem.BundleIdentifier, rhs: WildCard) -> Bool {
      lhs == rhs.bundleIdentifier
    }
  }
}
