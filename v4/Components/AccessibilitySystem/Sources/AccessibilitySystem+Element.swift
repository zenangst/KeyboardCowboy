import Foundation

public extension AccessibilitySystem {
  /// Session-scoped identity, not a persistent window ID or an IPC token.
  final class Element: Hashable {
    let key: UUID
    let scope: UUID

    init(key: UUID, scope: UUID) {
      self.key = key
      self.scope = scope
    }

    public static func == (lhs: Element, rhs: Element) -> Bool {
      lhs.scope == rhs.scope && lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(scope)
      hasher.combine(key)
    }
  }

  enum MissingValuePolicy: Sendable {
    case fail
    case skipNoValueOrUnsupported
  }

  struct TraversalBudget: Sendable {
    public var maximumNodes: Int
    public var maximumDepth: Int
    public var elapsedLimit: Duration

    public init(maximumNodes: Int = 1000, maximumDepth: Int = 64,
                elapsedLimit: Duration = .seconds(2)) {
      self.maximumNodes = maximumNodes
      self.maximumDepth = maximumDepth
      self.elapsedLimit = elapsedLimit
    }
  }
}
