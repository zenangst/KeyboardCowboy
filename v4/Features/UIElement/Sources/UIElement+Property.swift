import AccessibilitySystem

public extension UIElement {
  enum Property: Hashable, Sendable {
    case description, identifier, title, value, subrole

    var attribute: AccessibilitySystem.Attribute<String> {
      switch self {
      case .description: .accessibilityDescription
      case .identifier: .identifier
      case .title: .title
      case .value: .textValue
      case .subrole: .subrole
      }
    }
  }
}
