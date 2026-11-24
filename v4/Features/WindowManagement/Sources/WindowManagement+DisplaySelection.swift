import CoreGraphics

extension WindowManagement {
  static func visibleBounds(for window: CGRect, on displays: [Display]) -> CGRect? {
    guard let index = displayIndex(for: window, on: displays) else { return nil }
    return usableBounds(of: displays[index])
  }

  static func displayIndex(for window: CGRect, on displays: [Display]) -> Int? {
    guard isUsable(window) else { return nil }

    var bestArea: CGFloat = 0
    var selected: Int?
    for (index, display) in displays.enumerated() {
      guard usableBounds(of: display) != nil else { continue }
      let overlap = window.intersection(display.bounds)
      guard isUsable(overlap) else { continue }
      let area = overlap.width * overlap.height
      // Keep input order on a tie.
      if area.isFinite, area > bestArea {
        bestArea = area
        selected = index
      }
    }
    return selected
  }

  static func usableBounds(of display: Display) -> CGRect? {
    guard isUsable(display.bounds), isUsable(display.visibleBounds) else { return nil }
    let usable = display.visibleBounds.intersection(display.bounds)
    return isUsable(usable) ? usable : nil
  }

  static func centeredFrame(_ window: CGRect, in visible: CGRect) -> CGRect? {
    // Keep the title bar reachable when the existing window is too tall.
    let x = visible.midX - window.width / 2
    let y = max(visible.minY, visible.midY - window.height / 2)
    let result = CGRect(origin: CGPoint(x: x, y: y), size: window.size)
    return isUsable(result) ? result : nil
  }

  static func isUsable(_ frame: CGRect) -> Bool {
    frame.size.width > 0 && frame.size.height > 0 &&
      [frame.origin.x, frame.origin.y, frame.maxX, frame.maxY].allSatisfy(\.isFinite)
  }
}
