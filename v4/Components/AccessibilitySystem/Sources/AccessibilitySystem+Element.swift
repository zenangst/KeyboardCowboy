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
}
