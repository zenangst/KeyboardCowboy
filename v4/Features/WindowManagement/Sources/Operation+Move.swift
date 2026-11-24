import CoreGraphics

extension Operation {
  struct Move: Sendable {
    let direction: WindowManagement.Direction
    let distance: CGFloat
    let constraint: WindowManagement.MoveConstraint

    init(direction: WindowManagement.Direction, distance: CGFloat, constraint: WindowManagement.MoveConstraint) throws {
      guard distance.isFinite, distance >= 0 else { throw WindowManagement.MoveError.invalidDistance }
      if case .visibleArea(_, let padding) = constraint {
        guard padding.isFinite, padding >= 0 else { throw WindowManagement.MoveError.invalidPadding }
      }
      self.direction = direction
      self.distance = distance
      self.constraint = constraint
    }

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard WindowManagement.isUsable(original) else { return nil }
      guard distance != 0 else { return original }
      let offset = direction.offset
      var result = original.offsetBy(dx: offset.x * distance, dy: offset.y * distance)
      if case .visibleArea(let displays, let padding) = constraint {
        guard let visible = WindowManagement.visibleBounds(for: original, on: displays),
              padding < visible.width / 2, padding < visible.height / 2 else { return nil }
        let area = visible.insetBy(dx: padding, dy: padding)
        // Oversized windows cannot fit without resizing. Pin the oversized
        // axis at its leading/top edge so the title bar stays reachable.
        result.origin.x = min(max(result.origin.x, area.minX), max(area.minX, area.maxX - original.width))
        result.origin.y = min(max(result.origin.y, area.minY), max(area.minY, area.maxY - original.height))
      }
      return WindowManagement.isUsable(result) ? result : nil
    }
  }

  static func moveFocusedWindow<Window: Equatable>(
    focusedWindow: () throws -> Window?,
    frame: (Window) throws -> CGRect,
    requested: (CGRect) -> CGRect?,
    move: (CGPoint, Window) throws -> Void,
  ) throws -> WindowManagement.FrameResult? {
    guard let window = try focusedWindow() else { return nil }
    let original = try frame(window)
    guard let target = requested(original) else { return nil }
    if original.origin == target.origin {
      return .init(original: original, requested: target, observed: original)
    }
    guard try focusedWindow() == window else { return nil }
    try move(target.origin, window)
    return try .init(original: original, requested: target, observed: frame(window))
  }
}
