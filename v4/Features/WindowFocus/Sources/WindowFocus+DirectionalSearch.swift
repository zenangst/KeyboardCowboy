import CoreGraphics

public extension WindowFocus {
  enum DirectionalSearch {
    public enum Direction: CaseIterable, Sendable {
      case left, right, up, down
    }

    public struct Window: Sendable {
      public let id: CGWindowID
      public let frame: CGRect

      public init(id: CGWindowID, frame: CGRect) {
        self.id = id
        self.frame = frame
      }
    }

    public struct Match: Equatable, Sendable {
      public enum Branch: Equatable, Sendable { case twoWindowToggle, directHit, constrainedHit }

      public let windowID: CGWindowID
      public let direction: Direction
      public let branch: Branch
    }

    /// With one eligible window besides the anchor, try to resolve that window's exact
    /// AX identity before scanning. Return `nil` from `resolveAXIdentity` when unavailable.
    /// The primary scan uses top-left global coordinates. Supply eligible windows and
    /// visible display frames in their original order, and classify tiling on the initial
    /// probe display. The hit test must also return an exact AX window identity.
    /// This selector does not fall back to a display center or perform focus effects.
    public static func select(
      from anchor: Window,
      windows: [Window],
      direction: Direction,
      visibleFrames: [CGRect],
      tiling: Tiling? = nil,
      spacing: CGFloat = 0,
      mainDisplayFrame: CGRect? = nil,
      deadzoneSpacing: CGFloat? = nil,
      maxProbes: Int = 1024,
      resolveAXIdentity: ((Window) -> CGWindowID?)? = nil,
      hitAt: (CGPoint) throws -> CGWindowID?,
    ) throws -> Match? {
      try Task.checkCancellation()
      guard anchor.id != 0, valid(anchor.frame) else { return nil }

      let candidates = windows.filter { $0.id != 0 && $0.id != anchor.id && valid($0.frame) }
      guard let first = candidates.first else { return nil }

      if candidates.count == 1, let resolveAXIdentity {
        let resolvedID = resolveAXIdentity(first)
        try Task.checkCancellation()
        if resolvedID == first.id {
          return .init(windowID: first.id, direction: direction, branch: .twoWindowToggle)
        }
      }

      guard spacing.isFinite, spacing >= 0, maxProbes > 0 else { return nil }

      let displays = visibleFrames.filter(valid)
      guard !displays.isEmpty else { return nil }

      let bounds = candidates.dropFirst().reduce(first.frame) { $0.union($1.frame) }
      guard valid(bounds), (bounds.maxX + spacing).isFinite, (bounds.maxY + spacing).isFinite else { return nil }

      let frame = anchor.frame
      var probe = initialProbe(from: frame, direction: direction)
      let tiling = displays.contains(where: { $0.intersects(probe) }) ? tiling : nil
      switch tiling {
      case .topLeft: probe.origin.x = frame.minX + spacing
      case .topRight: probe.origin.x = frame.maxX - spacing - side
      default: break
      }

      var direction = direction
      var visited = Set<Probe>()
      let deadzones = deadzones(in: mainDisplayFrame, spacing: deadzoneSpacing ?? spacing)
      for _ in 0 ..< maxProbes {
        try Task.checkCancellation()
        probe.origin = direction.advance(probe.origin, by: side)
        guard valid(probe), direction.isInRange(probe, bounds: bounds, spacing: spacing),
              visited.insert(.init(x: probe.minX, y: probe.minY, direction: direction)).inserted else { return nil }

        let point = CGPoint(x: probe.midX, y: probe.midY)
        let inDeadzone = deadzones.contains { $0.contains(point) }
        let eligible = inDeadzone ? candidates.filter {
          direction.accepts($0.frame, relativeTo: frame) && probe.intersects($0.frame)
        } : candidates
        if !eligible.isEmpty {
          let hit = try hitAt(point)
          try Task.checkCancellation()
          if let hit, eligible.contains(where: { $0.id == hit }) {
            return .init(windowID: hit, direction: direction, branch: inDeadzone ? .constrainedHit : .directHit)
          }
        }

        guard let display = displays.first(where: { $0.intersects(probe) }) else { return nil }

        if let tiling, direction.isPastEdge(probe, of: display) { direction = tiling.reroute(direction) }
      }
      return nil
    }

    private static let side: CGFloat = 50

    private struct Probe: Hashable {
      let x: CGFloat
      let y: CGFloat
      let direction: Direction
    }

    private static func initialProbe(from frame: CGRect, direction: Direction) -> CGRect {
      let origin: CGPoint = switch direction {
      case .left: CGPoint(x: frame.minX - side, y: frame.minY)
      case .right: CGPoint(x: frame.maxX + side, y: frame.minY)
      case .up: CGPoint(x: frame.midX + side, y: frame.minY - side / 2)
      case .down: CGPoint(x: frame.midX - side, y: frame.minY)
      }
      return CGRect(origin: origin, size: CGSize(width: side, height: side))
    }

    private static func deadzones(in frame: CGRect?, spacing: CGFloat) -> [CGRect] {
      guard let frame, valid(frame), spacing.isFinite, spacing > 0 else { return [] }

      return [
        CGRect(x: frame.midX - spacing / 2, y: frame.minY, width: spacing, height: frame.height),
        CGRect(x: frame.minX, y: frame.midY, width: frame.width, height: spacing),
      ]
    }

    private static func valid(_ frame: CGRect) -> Bool {
      !frame.isInfinite && !frame.isNull && frame.size.width > 0 && frame.size.height > 0
        && frame.minX.isFinite && frame.maxX.isFinite
        && frame.minY.isFinite && frame.maxY.isFinite
    }
  }
}
