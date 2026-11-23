public extension Open {
  struct WebApp: Sendable {
    public enum Outcome: Sendable {
      case notOpened, pollingSkipped, noMatch, raised
    }

    private let operation = Operation.WebApp()

    public init() {}

    @discardableResult
    public func open(_ path: String, application: TargetApplication) async throws -> Outcome {
      try await operation(path, application: application)
    }
  }
}
