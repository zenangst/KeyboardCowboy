public extension Open {
  /// Route implementations and host callbacks used by the executor.
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

    /// Composes the package's Finder and generic operations while keeping host
    /// interception and the not-yet-implemented browser routes explicit.
    public init(
      finder: Finder,
      generic: Generic = Generic(),
      openHost: @escaping @Sendable () async -> Void,
      openBrowser: @escaping @Sendable (String, TargetApplication?, Bool) async throws -> Void,
      openWebApp: @escaping @Sendable (String, TargetApplication, Bool) async throws -> Void
    ) {
      self.init(
        openHost: openHost,
        openFinder: { try await finder.open($0, checkCancellation: $1) },
        openBrowser: openBrowser,
        openWebApp: openWebApp,
        openGeneric: { try await generic.open($0, application: $1) },
        isDirectory: { try generic.isDirectory($0) }
      )
    }
  }
}
