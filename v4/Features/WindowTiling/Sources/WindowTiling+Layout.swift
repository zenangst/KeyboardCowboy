import CoreGraphics

public extension WindowTiling {
  /// Identifies a tile from settled geometry in top-left global coordinates.
  /// `margin` is the inset at display edges and the gap between adjacent tiles.
  /// Freely placed, app-clamped, and off-screen frames may not match any tile.
  static func classify(
    _ frame: CGRect, in visibleBounds: CGRect, margin: CGFloat, tolerance: CGFloat = 1,
  ) -> Action? {
    guard usable(frame), validLayout(visibleBounds, margin: margin),
          tolerance.isFinite, tolerance >= 0 else { return nil }

    let inset = visibleBounds.insetBy(dx: margin, dy: margin)
    for (action, candidate) in tiles(in: inset, gap: margin) where framesMatch(frame, candidate, tolerance: tolerance) {
      return action
    }
    if inset.contains(frame), abs(frame.midX - inset.midX) <= tolerance, abs(frame.midY - inset.midY) <= tolerance {
      return .center
    }
    return nil
  }

  /// Geometry of a single-window tile. Center preserves the window's size.
  /// Menu-only actions and group arrangements have no single target frame.
  static func targetFrame(for action: Action, window: CGRect, in bounds: CGRect, margin: CGFloat) -> CGRect? {
    guard usable(window), validLayout(bounds, margin: margin) else { return nil }
    let inset = bounds.insetBy(dx: margin, dy: margin)
    if action == .center {
      guard window.width <= inset.width, window.height <= inset.height else { return nil }
      return CGRect(x: inset.midX - window.width / 2, y: inset.midY - window.height / 2,
                    width: window.width, height: window.height)
    }
    return tiles(in: inset, gap: margin).first { $0.0 == action }?.1
  }

  private static func tiles(in inset: CGRect, gap: CGFloat) -> [(Action, CGRect)] {
    let left = inset.minX, right = inset.maxX
    let top = inset.minY, bottom = inset.maxY
    let leftEnd = inset.midX - gap / 2, rightStart = inset.midX + gap / 2
    let topEnd = inset.midY - gap / 2, bottomStart = inset.midY + gap / 2
    let candidates: [(Action, CGFloat, CGFloat, CGFloat, CGFloat)] = [
      (.fill, left, top, right, bottom),
      (.left, left, top, leftEnd, bottom),
      (.right, rightStart, top, right, bottom),
      (.top, left, top, right, topEnd),
      (.bottom, left, bottomStart, right, bottom),
      (.topLeft, left, top, leftEnd, topEnd),
      (.topRight, rightStart, top, right, topEnd),
      (.bottomLeft, left, bottomStart, leftEnd, bottom),
      (.bottomRight, rightStart, bottomStart, right, bottom),
    ]
    return candidates.compactMap { action, x1, y1, x2, y2 in
      guard x1 < x2, y1 < y2 else { return nil }
      return (action, CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
    }
  }

  private static func framesMatch(_ lhs: CGRect, _ rhs: CGRect, tolerance: CGFloat) -> Bool {
    abs(lhs.minX - rhs.minX) <= tolerance && abs(lhs.minY - rhs.minY) <= tolerance
      && abs(lhs.maxX - rhs.maxX) <= tolerance && abs(lhs.maxY - rhs.maxY) <= tolerance
  }

  internal static func validLayout(_ bounds: CGRect, margin: CGFloat) -> Bool {
    usable(bounds) && margin.isFinite && margin >= 0 && margin < bounds.width / 2 && margin < bounds.height / 2
  }

  private static func usable(_ rect: CGRect) -> Bool {
    rect.size.width > 0 && rect.size.height > 0 &&
      [rect.minX, rect.minY, rect.maxX, rect.maxY].allSatisfy(\.isFinite)
  }
}
