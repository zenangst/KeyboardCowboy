import CoreGraphics

public extension WindowFocus {
  /// Selection state for repeated center focus invocations.
  struct CenterCycle: Sendable {
    private var geometry: Geometry?
    private var cycle = SpatialCycle()

    public init() {}

    /// Both display frames use top-left global coordinates. Supply fresh, eligible
    /// windows in front-to-back order. The host must verify the returned ID before
    /// focusing it, and reset on external focus or Space changes.
    public mutating func select(
      in display: CGRect, visibleFrame: CGRect, spacing: CGFloat = 0,
      windows: [SpatialWindow], focusedWindowID: CGWindowID?,
    ) -> CGWindowID? {
      let minX = visibleFrame.minX + spacing
      let maxX = visibleFrame.maxX - 2 * spacing
      // Legacy probe occupies the 2×2 points immediately above and left of center.
      let probe = CGRect(x: display.midX - 2, y: display.midY - 2, width: 2, height: 2)
      guard SpatialWindow.isValid(display), SpatialWindow.isValid(visibleFrame),
            spacing.isFinite, spacing >= 0, minX < maxX, display.contains(probe) else {
        reset()
        return nil
      }

      let geometry = Geometry(display: display, visibleFrame: visibleFrame, spacing: spacing)
      if self.geometry != geometry {
        reset()
        self.geometry = geometry
      }

      let inventory = windows.filter { $0.isValid && $0.overlaps(probe) }
      return cycle.select(windows: inventory, focusedWindowID: focusedWindowID) {
        $0.frame.minX > minX && $0.frame.maxX < maxX
      }
    }

    public mutating func reset() {
      geometry = nil
      cycle = .init()
    }

    private struct Geometry: Equatable, Sendable {
      let display: CGRect
      let visibleFrame: CGRect
      let spacing: CGFloat
    }
  }
}
