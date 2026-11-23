public extension Open {
  /// Retargets Finder's front window. The host executes the script with a fresh
  /// user-environment-resolving snapshot and an empty runtime dictionary.
  struct Finder: Sendable {
    private let operation: Operation.Finder

    public init(executeScript: @escaping @Sendable (
      _ name: String,
      _ source: String,
      _ checkCancellation: Bool,
    ) async throws -> Void) {
      operation = Operation.Finder(executeScript: executeScript)
    }

    public func open(_ path: String, checkCancellation: Bool) async throws {
      try await operation(path, checkCancellation: checkCancellation)
    }
  }
}
