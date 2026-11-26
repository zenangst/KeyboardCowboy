public extension Open {
  /// Application data supplied by the host, without resolving it by name.
  struct TargetApplication: Sendable, Equatable {
    public let bundleIdentifier: String
    public let bundleName: String
    public let displayName: String
    public let path: String

    public init(bundleIdentifier: String, bundleName: String, displayName: String, path: String) {
      self.bundleIdentifier = bundleIdentifier
      self.bundleName = bundleName
      self.displayName = displayName
      self.path = path
    }
  }
}
