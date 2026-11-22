import AccessibilitySystem
import CoreGraphics

public enum Mouse {
  public enum Anchor: Codable, Hashable, Sendable {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
    case custom(x: Int, y: Int)

    /// Uses AX global screen coordinates. Custom coordinates are absolute.
    public func point(in frame: CGRect) -> CGPoint {
      let point: CGPoint = switch self {
      case .topLeading: CGPoint(x: frame.minX, y: frame.minY)
      case .top: CGPoint(x: frame.midX, y: frame.minY)
      case .topTrailing: CGPoint(x: frame.maxX, y: frame.minY)
      case .leading: CGPoint(x: frame.minX, y: frame.midY)
      case .center: CGPoint(x: frame.midX, y: frame.midY)
      case .trailing: CGPoint(x: frame.maxX, y: frame.midY)
      case .bottomLeading: CGPoint(x: frame.minX, y: frame.maxY)
      case .bottom: CGPoint(x: frame.midX, y: frame.maxY)
      case .bottomTrailing: CGPoint(x: frame.maxX, y: frame.maxY)
      case .custom(let x, let y): CGPoint(x: x, y: y)
      }
      return CGPoint(x: point.x + 5, y: point.y + 5)
    }
  }

  /// Resolves roles that use their own frame. Roles requiring specialized
  /// resolvers return nil rather than falling back to an unrelated click point.
  public static func focusedTarget(
    at anchor: Anchor,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CGPoint? {
    try await accessibility.withFocusedElement { element in
      try target(roleDescription: element.read(.roleDescription), at: anchor) {
        try CGRect(origin: element.read(.position), size: element.read(.size))
      }
    }
  }

  static func target(roleDescription: String, at anchor: Anchor, frame: () throws -> CGRect) rethrows -> CGPoint? {
    switch roleDescription {
    case "image", "outline row", "text", "text field":
      try anchor.point(in: frame())
    default:
      nil
    }
  }
}
