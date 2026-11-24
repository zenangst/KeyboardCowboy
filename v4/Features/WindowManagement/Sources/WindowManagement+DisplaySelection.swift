import CoreGraphics

extension WindowManagement {
  static func visibleBounds(for window: CGRect, on displays: [Display]) -> CGRect? {
    guard isUsable(window) else { return nil }

    var bestArea: CGFloat = 0
    var visible: CGRect?
    for display in displays {
      guard isUsable(display.bounds), isUsable(display.visibleBounds) else { continue }
      let usable = display.visibleBounds.intersection(display.bounds)
      let overlap = window.intersection(display.bounds)
      guard isUsable(usable), isUsable(overlap) else { continue }
      let area = overlap.width * overlap.height
      // Keep input order on a tie.
      if area.isFinite, area > bestArea {
        bestArea = area
        visible = usable
      }
    }
    return visible
  }

  static func isUsable(_ frame: CGRect) -> Bool {
    frame.size.width > 0 && frame.size.height > 0 &&
      [frame.origin.x, frame.origin.y, frame.maxX, frame.maxY].allSatisfy(\.isFinite)
  }
}
