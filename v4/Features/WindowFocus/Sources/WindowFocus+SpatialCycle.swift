import CoreGraphics

extension WindowFocus {
  struct SpatialCycle: Sendable {
    private var order: [CGWindowID] = []
    private var consumed: Set<CGWindowID> = []

    mutating func select(
      windows: [SpatialWindow], focusedWindowID: CGWindowID?, accepts: (SpatialWindow) -> Bool,
    ) -> CGWindowID? {
      let present = Set(windows.map(\.id))
      order.removeAll { !present.contains($0) }
      consumed.formIntersection(present)
      var ordered = Set(order)
      for window in windows where ordered.insert(window.id).inserted {
        order.append(window.id)
      }

      let active = focusedWindowID ?? order.first
      if let active, present.contains(active) { consumed.insert(active) }
      let candidates = Set(windows.filter { $0.id != active && accepts($0) }.map(\.id))
      if let next = order.first(where: { candidates.contains($0) && !consumed.contains($0) }) { return next }

      consumed.removeAll(keepingCapacity: true)
      return order.first(where: candidates.contains)
    }
  }
}
