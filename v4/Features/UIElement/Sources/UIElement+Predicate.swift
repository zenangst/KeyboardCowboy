import AccessibilitySystem
import Foundation

public extension UIElement {
  struct Predicate: Sendable {
    public let role: String?
    public let properties: [Property]
    public let comparison: Comparison
    public let value: String

    /// A nil role matches any known AX role.
    public init(role: String? = nil, properties: [Property], comparison: Comparison, value: String) {
      self.role = role
      self.properties = properties
      self.comparison = comparison
      self.value = value
    }
  }
}
