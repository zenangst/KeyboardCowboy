import AccessibilitySystem
import Commands

public enum MenuBar {
  public typealias Token = Command.MenuBar.Token

  public enum ExecutionError: Error, Equatable {
    case emptyTokens, menuBarUnavailable, invalidTraversalBudget, traversalLimitReached
  }

  /// Picks the first matching menu path in the supplied application's AX menu
  /// bar. Returns false when no path matches. The caller resolves the PID and
  /// handles any launch or activation needed by the target application.
  @discardableResult
  public static func execute(
    _ tokens: [Token], processIdentifier: Int32,
    using accessibility: AccessibilitySystem.Client = .init(),
    budget: AccessibilitySystem.TraversalBudget = .init(),
  ) async throws -> Bool {
    do {
      return try await executeAttempt(tokens, processIdentifier: processIdentifier, using: accessibility, budget: budget)
    } catch let failure as StartupReadFailure {
      throw failure.underlying
    }
  }

  /// Only emitted by menu reads, never by the action or by session teardown.
  struct StartupReadFailure: Error {
    let underlying: any Error
  }

  static func executeAttempt(
    _ tokens: [Token], processIdentifier: Int32,
    using accessibility: AccessibilitySystem.Client,
    budget: AccessibilitySystem.TraversalBudget,
  ) async throws -> Bool {
    guard !tokens.isEmpty else { throw ExecutionError.emptyTokens }

    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try execute(
        tokens, budget: budget, root: session.menuBar,
        children: { element in try optional { try session.children(of: element) } ?? [] },
        enabled: { element in try optional { try session.read(.enabled, of: element) } ?? false },
        title: { element in try optional { try session.read(.title, of: element) } },
        checkpoint: session.checkpoint,
        pick: { try session.perform(.pick, on: $0) },
        mapReadError: { error in
          guard let failure = error as? AccessibilitySystem.Failure, failure.kind == .cannotComplete else {
            return error
          }
          return StartupReadFailure(underlying: failure)
        },
      )
    }
  }

  static func execute<Node: Hashable>(
    _ tokens: [Token],
    budget: AccessibilitySystem.TraversalBudget = .init(),
    root: () throws -> Node?,
    children: (Node) throws -> [Node],
    enabled: (Node) throws -> Bool,
    title: (Node) throws -> String?,
    checkpoint: () throws -> Void, pick: (Node) throws -> Void,
    mapReadError: (any Error) -> any Error = { $0 },
  ) throws -> Bool {
    guard !tokens.isEmpty else { throw ExecutionError.emptyTokens }
    guard budget.maximumNodes > 0, budget.maximumDepth >= 0, budget.elapsedLimit > .zero else {
      throw ExecutionError.invalidTraversalBudget
    }

    let deadline = ContinuousClock.now + budget.elapsedLimit
    func check() throws {
      try checkpoint()
      guard ContinuousClock.now < deadline else { throw ExecutionError.traversalLimitReached }
    }
    func read<Value>(_ operation: () throws -> Value) throws -> Value {
      do {
        return try operation()
      } catch {
        throw mapReadError(error)
      }
    }

    try check()
    guard var current = try read(root) else { throw ExecutionError.menuBarUnavailable }

    var path: Set<Node> = []
    var examined = 1

    func firstMatch(_ token: Token) throws -> (Node, Set<Node>)? {
      var stack = [([current][...], path)]
      var visited = path.union([current])
      while let (parents, ancestors) = stack.popLast() {
        var remaining = parents
        guard let parent = remaining.popFirst() else { continue }

        if !remaining.isEmpty { stack.append((remaining, ancestors)) }

        try check()
        let items = try read { try children(parent) }
        try check()
        var fallback: [Node] = []
        // Scan siblings before descending, so a direct match beats any fallback.
        for item in items where visited.insert(item).inserted {
          try check()
          guard examined < budget.maximumNodes, ancestors.count < budget.maximumDepth else {
            throw ExecutionError.traversalLimitReached
          }

          examined += 1
          let isEnabled = try read { try enabled(item) }
          try check()
          if isEnabled {
            let value = try read { try title(item) }
            try check()
            if let value, token.matches(value) {
              return (item, ancestors.union([parent]))
            }
          }
          fallback.append(item)
        }
        if !fallback.isEmpty { stack.append((fallback[...], ancestors.union([parent]))) }
      }
      return nil
    }

    for token in tokens {
      guard let match = try firstMatch(token) else { return false }

      // Once a token matches, commit to that branch for the remaining tokens.
      (current, path) = match
    }
    try check()
    try pick(current)
    return true
  }

  private static func optional<Value>(_ read: () throws -> Value) throws -> Value? {
    do {
      return try read()
    } catch let failure as AccessibilitySystem.Failure
      where failure.kind == .noValue || failure.kind == .attributeUnsupported {
      return nil
    }
  }
}

private extension MenuBar.Token {
  func matches(_ title: String) -> Bool {
    switch self {
    case .menuItem(let name): title.hasPrefix(name)
    case .menuItems(let name, let fallbackName): title.hasPrefix(name) || title.hasPrefix(fallbackName)
    }
  }
}
