import ApplicationSystem

public extension Application.Executor {
  struct SelfApplicationHandler: Sendable {
    let bundleIdentifier: ApplicationSystem.BundleIdentifier
    let open: @Sendable () async -> Void

    public init(bundleIdentifier: ApplicationSystem.BundleIdentifier, open: @escaping @Sendable () async -> Void) {
      self.bundleIdentifier = bundleIdentifier
      self.open = open
    }
  }
}
