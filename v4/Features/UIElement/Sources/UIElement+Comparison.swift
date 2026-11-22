import AccessibilitySystem

public extension UIElement {
  enum Comparison: Sendable {
    case equals, contains, prefix, suffix

    func matches(_ candidate: String, _ value: String) -> Bool {
      switch self {
      case .equals: candidate == value
      case .contains: candidate.contains(value)
      case .prefix: candidate.hasPrefix(value)
      case .suffix: candidate.hasSuffix(value)
      }
    }
  }
}
