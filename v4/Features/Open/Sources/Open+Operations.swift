public extension Open {
  /// Host-supplied route implementations until concrete operations are available.
  struct Operations: Sendable {
    let openHost: @Sendable () async -> Void
    let openFinder: @Sendable (String, Bool) async throws -> Void
    let openBrowser: @Sendable (String, TargetApplication?, Bool) async throws -> Void
    let openWebApp: @Sendable (String, TargetApplication, Bool) async throws -> Void
    let openGeneric: @Sendable (String, TargetApplication?) async throws -> Void
    let isDirectory: @Sendable (String) async throws -> Bool

    public init(
      openHost: @escaping @Sendable () async -> Void,
      openFinder: @escaping @Sendable (String, Bool) async throws -> Void,
      openBrowser: @escaping @Sendable (String, TargetApplication?, Bool) async throws -> Void,
      openWebApp: @escaping @Sendable (String, TargetApplication, Bool) async throws -> Void,
      openGeneric: @escaping @Sendable (String, TargetApplication?) async throws -> Void,
      isDirectory: @escaping @Sendable (String) async throws -> Bool
    ) {
      self.openHost = openHost
      self.openFinder = openFinder
      self.openBrowser = openBrowser
      self.openWebApp = openWebApp
      self.openGeneric = openGeneric
      self.isDirectory = isDirectory
    }
  }
}
