public extension Workspaces {
  struct Application: Sendable {
    public let bundleIdentifier: String
    public let onlyWhenRunning: Bool

    public init(_ bundleIdentifier: String, onlyWhenRunning: Bool = false) {
      self.bundleIdentifier = bundleIdentifier
      self.onlyWhenRunning = onlyWhenRunning
    }
  }
}
