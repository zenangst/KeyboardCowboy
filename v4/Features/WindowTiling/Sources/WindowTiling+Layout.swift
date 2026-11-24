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
    let left = inset.minX, right = inset.maxX
    let top = inset.minY, bottom = inset.maxY
    let leftEnd = inset.midX - margin / 2, rightStart = inset.midX + margin / 2
    let topEnd = inset.midY - margin / 2, bottomStart = inset.midY + margin / 2
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
    for (action, x1, y1, x2, y2) in candidates where x1 < x2 && y1 < y2 {
      if abs(frame.minX - x1) <= tolerance, abs(frame.minY - y1) <= tolerance,
         abs(frame.maxX - x2) <= tolerance, abs(frame.maxY - y2) <= tolerance {
        return action
      }
    }
    if inset.contains(frame), abs(frame.midX - inset.midX) <= tolerance, abs(frame.midY - inset.midY) <= tolerance {
      return .center
    }
    return nil
  }

  internal static func validLayout(_ bounds: CGRect, margin: CGFloat) -> Bool {
    usable(bounds) && margin.isFinite && margin >= 0 && margin < bounds.width / 2 && margin < bounds.height / 2
  }

  private static func usable(_ rect: CGRect) -> Bool {
    rect.size.width > 0 && rect.size.height > 0 &&
      [rect.minX, rect.minY, rect.maxX, rect.maxY].allSatisfy(\.isFinite)
  }
}
