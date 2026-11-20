
public extension AccessibilitySystem {
  struct Failure: Error, Sendable {
    public enum Kind: Sendable {
      case noValue, attributeUnsupported, actionUnsupported, invalidElement, apiDisabled
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
}
