public extension Open {
  /// Generic workspace opening and directory metadata used by the executor fallback.
  struct Generic: Sendable {
    private let operation: Operation.Generic

    public init() {
      self.init(environment: .production)
    }

    init(environment: Environment) {
      operation = Operation.Generic(environment: environment)
    }

    public func open(_ path: String, application: TargetApplication? = nil) async throws {
      try await operation(path, application: application)
    }

    public func isDirectory(_ path: String) throws -> Bool {
      try operation.isDirectory(path)
    }
  }
}
