import AccessibilitySystem
import Foundation

public extension UIElement {
  struct Predicate: Sendable {
    public let role: AccessibilitySystem.Role?
    public let properties: [Property]
    public let comparison: Comparison
    public let value: String

    /// A nil role matches any reported AX role.
    public init(role: AccessibilitySystem.Role? = nil, properties: [Property], comparison: Comparison, value: String) {
      self.role = role
      self.properties = properties
      self.comparison = comparison
      self.value = value
    }
  }
}
