import CoreGraphics

public extension WindowFocus {
  /// Selection state for repeated quarter invocations. It never raises or activates a window.
  struct QuarterCycle: Sendable {
    public struct Window: Sendable {
      public let id: CGWindowID
      public let frame: CGRect

      public init(id: CGWindowID, frame: CGRect) {
        self.id = id
        self.frame = frame
      }
    }

    private var quarter: Quarter?
    private var probe: CGRect?
    private var order: [CGWindowID] = []
    private var consumed: Set<CGWindowID> = []

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

      let inventory = windows.filter {
        $0.id != 0 && !$0.frame.isNull && !$0.frame.isInfinite && !$0.frame.isEmpty
          && $0.frame.minX.isFinite && $0.frame.minY.isFinite && $0.frame.maxX.isFinite && $0.frame.maxY.isFinite
      }
      let present = Set(inventory.map(\.id))
      order.removeAll { !present.contains($0) }
      consumed.formIntersection(present)
      var ordered = Set(order)
      for window in inventory where ordered.insert(window.id).inserted {
        order.append(window.id)
      }

      let active = focusedWindowID ?? order.first
      if let active, present.contains(active) { consumed.insert(active) }
      let candidates = Set(inventory.lazy.filter {
        // An edge-only touch is not an intersection with the probe area.
        let overlap = probe.intersection($0.frame)
        return !overlap.isNull && !overlap.isEmpty && $0.id != active
      }.map(\.id))
      if let next = order.first(where: { candidates.contains($0) && !consumed.contains($0) }) { return next }

      consumed.removeAll(keepingCapacity: true)
      return order.first(where: candidates.contains)
    }

    public mutating func reset() {
      quarter = nil
      probe = nil
      order.removeAll(keepingCapacity: true)
      consumed.removeAll(keepingCapacity: true)
    }
  }
}
