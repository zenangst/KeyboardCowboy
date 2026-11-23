import AccessibilitySystem

public extension Open {
  /// Browser reuse orchestration. Searches accessibility windows before tabs.
  struct Browser: Sendable {
    private let operation: Operation.Browser

    public init(tabSearch: BrowserTabSearch, accessibility: AccessibilitySystem.Client = .init()) {
      operation = Operation.Browser(tabSearch: tabSearch, accessibility: accessibility)
    }

    /// The supplied operation must throw AX failures, not report them as no match.
    public init(
      tabSearch: BrowserTabSearch,
      raiseMatchingWindow: @escaping @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool,
    ) {
      self.init(environment: .production, tabSearch: tabSearch, raiseMatchingWindow: raiseMatchingWindow)
    }

    init(
      environment: Environment,
      tabSearch: BrowserTabSearch,
      raiseMatchingWindow: @escaping @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool,
    ) {
      operation = Operation.Browser(
        environment: environment,
        tabSearch: tabSearch,
        raiseMatchingWindow: raiseMatchingWindow,
      )
    }

    public func open(_ path: String, application: TargetApplication? = nil, checkCancellation: Bool) async throws {
      try await operation(path, application: application, checkCancellation: checkCancellation)
    }
  }
}
