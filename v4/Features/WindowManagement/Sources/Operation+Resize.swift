import CoreGraphics

extension Operation {
  struct Resize: Sendable {
    let change: WindowManagement.ResizeChange
    let direction: WindowManagement.Direction
    let distance: CGFloat
    let constraint: WindowManagement.ResizeConstraint

    init(change: WindowManagement.ResizeChange, direction: WindowManagement.Direction, distance: CGFloat,
         constraint: WindowManagement.ResizeConstraint) throws {
      guard distance.isFinite, distance >= 0 else { throw WindowManagement.ResizeError.invalidDistance }

      if case .visibleArea(_, let padding) = constraint {
        guard padding.isFinite, padding >= 0 else { throw WindowManagement.ResizeError.invalidPadding }
      }
      self.change = change
      self.direction = direction
      self.distance = distance
      self.constraint = constraint
    }

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard WindowManagement.isUsable(original) else { return nil }

      if distance == 0 { return original }

      var bounds: CGRect?
      if case .visibleArea(let displays, let padding) = constraint {
        guard let visible = WindowManagement.visibleBounds(for: original, on: displays),
              padding < visible.width / 2, padding < visible.height / 2 else { return nil }

        let usable = visible.insetBy(dx: padding, dy: padding)
        guard usable.contains(original) else { return nil }

        bounds = usable
      }

      let offset = direction.offset
      let x = axis(
        origin: original.minX,
        length: original.width,
        edge: offset.x,
        lower: bounds?.minX,
        upper: bounds?.maxX,
      )
      let y = axis(
        origin: original.minY,
        length: original.height,
        edge: offset.y,
        lower: bounds?.minY,
        upper: bounds?.maxY,
      )
      let result = CGRect(x: x.origin, y: y.origin, width: x.length, height: y.length)

      return WindowManagement.isUsable(result) ? result : nil
    }

    private func axis(origin: CGFloat, length: CGFloat, edge: CGFloat, lower: CGFloat?, upper: CGFloat?)
      -> (origin: CGFloat, length: CGFloat) {
      guard edge != 0 else { return (origin, length) }

      let limit = edge < 0 ? lower.map { origin - $0 } : upper.map { $0 - (origin + length) }
      let delta: CGFloat = switch change {
      case .grow: min(distance, limit ?? distance)
      // Never request less than a point, or grow a window that's already smaller.
      case .shrink: -min(distance, max(0, length - 1))
      }
      return (edge < 0 ? origin - delta : origin, length + delta)
    }
  }
}
