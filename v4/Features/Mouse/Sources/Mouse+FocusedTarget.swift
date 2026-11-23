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

  public enum TargetError: Error {
    case noSelectedChild
  }

  /// Resolves direct-frame roles, groups, tables, and outlines. Other roles
  /// return nil rather than falling back to an unrelated click point.
  public static func focusedTarget(
    at anchor: Anchor,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CGPoint? {
    try await accessibility.withFocusedElement { element in
      let role = try element.read(.roleDescription)
      if role == "group", let child = try element.firstChild(where: { child in
        isGroupTarget(focused: { try child.read(.focused) },
                      selected: { try child.read(.selected) })
      }) {
        return try anchor.point(in: CGRect(origin: child.read(.position),
                                           size: child.read(.size)))
      }
      return try target(
        roleDescription: role,
        at: anchor, selectedFrame: {
          let child = try element.firstChild { (try? $0.read(.selected)) == true }
          return try child.map { try CGRect(origin: $0.read(.position), size: $0.read(.size)) }
        }, frame: {
          try CGRect(origin: element.read(.position), size: element.read(.size))
        })
    }
  }

  static func target(
    roleDescription: String, at anchor: Anchor,
    selectedFrame: () throws -> CGRect?, frame: () throws -> CGRect,
  ) throws -> CGPoint? {
    switch roleDescription {
    case "group", "image", "outline row", "text", "text field":
      return try anchor.point(in: frame())
    case "table", "outline":
      guard let frame = try selectedFrame() else { throw TargetError.noSelectedChild }

      return anchor.point(in: frame)
    default:
      return nil
    }
  }

  static func isGroupTarget(focused: () throws -> Bool, selected: () throws -> Bool) -> Bool {
    (try? focused()) == true || (try? selected()) == true
  }
}
