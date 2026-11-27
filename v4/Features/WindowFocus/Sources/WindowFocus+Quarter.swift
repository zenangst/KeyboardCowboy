import CoreGraphics

public extension WindowFocus {
  enum Quarter: CaseIterable, Sendable {
    case topLeft, topRight, bottomLeft, bottomRight

    /// The legacy corner probe, in top-left global coordinates.
    public func probe(in display: CGRect, spacing: CGFloat = 0) -> CGRect? {
      guard !display.isNull, !display.isInfinite, display.size.width > 0, display.size.height > 0,
            display.minX.isFinite, display.minY.isFinite, display.maxX.isFinite, display.maxY.isFinite,
            spacing.isFinite, spacing >= 0 else { return nil }
      let width = display.width * 0.1
      let height = display.height * 0.175
      let atLeft = self == .topLeft || self == .bottomLeft
      let atTop = self == .topLeft || self == .topRight
      let probe = CGRect(x: atLeft ? display.minX + spacing : display.maxX - width - spacing,
                         y: atTop ? display.minY + spacing : display.maxY - height - spacing,
                         width: width, height: height)
      return display.contains(probe) && !probe.isEmpty ? probe : nil
    }
  }
}
