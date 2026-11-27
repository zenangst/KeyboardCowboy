import CoreGraphics

public extension WindowFocus {
  /// Selection state for repeated quarter invocations. It never raises or activates a window.
  struct QuarterCycle: Sendable {
    public typealias Window = SpatialWindow

    private var quarter: Quarter?
    private var probe: CGRect?
    private var cycle = SpatialCycle()

    public init() {}

    /// Supply a fresh front-to-back inventory of eligible on-screen windows, including
    /// eligible windows behind others. Existing IDs keep their cycle order after a raise.
    /// Merely selecting a candidate does not consume it. If no focus ID is available,
    /// the first window in cycle order serves as the active fallback. The host must
    /// resolve the returned ID exactly and reset on external focus or Space changes.
    public mutating func select(
      _ quarter: Quarter, in display: CGRect, spacing: CGFloat = 0,
      windows: [Window], focusedWindowID: CGWindowID?,
    ) -> CGWindowID? {
      guard let probe = quarter.probe(in: display, spacing: spacing) else {
        reset()
        return nil
      }
      if self.quarter != quarter || self.probe != probe {
        reset()
        self.quarter = quarter
        self.probe = probe
      }

      return cycle.select(windows: windows.filter(\.isValid), focusedWindowID: focusedWindowID) { $0.overlaps(probe) }
    }

    public mutating func reset() {
      quarter = nil
      probe = nil
      cycle = .init()
    }
  }
}
