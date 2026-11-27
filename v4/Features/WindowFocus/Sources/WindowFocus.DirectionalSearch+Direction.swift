import CoreGraphics

extension WindowFocus.DirectionalSearch.Direction {
  func advance(_ point: CGPoint, by step: CGFloat) -> CGPoint {
    switch self {
    case .left: CGPoint(x: point.x - step, y: point.y)
    case .right: CGPoint(x: point.x + step, y: point.y)
    case .up: CGPoint(x: point.x, y: point.y - step)
    case .down: CGPoint(x: point.x, y: point.y + step)
    }
  }

  func isInRange(_ probe: CGRect, bounds: CGRect, spacing: CGFloat) -> Bool {
    switch self {
    case .left: probe.maxX >= bounds.minX
    case .right: probe.minX <= bounds.maxX + spacing
    case .up: probe.maxY >= bounds.minY + spacing
    case .down: probe.maxY + probe.height < bounds.maxY + spacing
    }
  }

  func isPastEdge(_ probe: CGRect, of display: CGRect) -> Bool {
    switch self {
    case .left: probe.minX - probe.width / 2 < display.minX
    case .right: probe.maxX + probe.width / 2 > display.maxX
    case .up: probe.minY < display.minY
    case .down: probe.minY > display.maxY
    }
  }

  func accepts(_ candidate: CGRect, relativeTo anchor: CGRect) -> Bool {
    guard !anchor.contains(candidate) else { return false }
    let dx = candidate.minX - anchor.minX
    let dy = candidate.minY - anchor.minY
    return switch self {
    case .left: dx < -2
    case .right: dx > 2 && candidate.maxX != anchor.maxX
    case .up: abs(dy) > 2
    case .down: dy > 2 && candidate.maxY != anchor.maxY
    }
  }
}
