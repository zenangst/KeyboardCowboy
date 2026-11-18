import Foundation

public enum AccessibilitySystem {}

public extension AccessibilitySystem {
  struct Configuration: Sendable {
    /// Per-message timeout, not an overall transaction deadline.
    public var messagingTimeout: Duration

    public init(messagingTimeout: Duration = .milliseconds(250)) {
      self.messagingTimeout = messagingTimeout
    }
  }

  struct Failure: Error, Sendable {
    public enum Kind: Sendable {
      case noValue, attributeUnsupported, invalidElement, apiDisabled
      case cannotComplete, malformedValue, traversalLimitReached, expiredScope
      case invalidConfiguration, other
    }

    public let kind: Kind
    public let operation: String
    public let rawAXStatus: Int32?

    init(_ kind: Kind, operation: String, rawAXStatus: Int32? = nil) {
      self.kind = kind
      self.operation = operation
      self.rawAXStatus = rawAXStatus
    }
  }

  struct Attribute<Value> {
    let name: String
    let decode: (ReadValue) throws -> Value
  }

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

public extension AccessibilitySystem.Attribute where Value == String {
  static var role: Self {
    Self(name: "AXRole") { value in
      guard case .string(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXRole")
      }

      return result
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == URL {
  static var url: Self {
    Self(name: "AXURL") { value in
      guard case .url(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXURL")
      }

      return result
    }
  }
}
