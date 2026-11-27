import CoreGraphics

public extension WindowFocus {
  struct SpatialWindow: Sendable {
    public let id: CGWindowID
    public let frame: CGRect

    public init(id: CGWindowID, frame: CGRect) {
      self.id = id
      self.frame = frame
    }

    var isValid: Bool { id != 0 && Self.isValid(frame) }

    static func isValid(_ frame: CGRect) -> Bool {
      !frame.isNull && !frame.isInfinite && frame.size.width > 0 && frame.size.height > 0
        && frame.minX.isFinite && frame.minY.isFinite && frame.maxX.isFinite && frame.maxY.isFinite
    }

    func overlaps(_ probe: CGRect) -> Bool {
      // An edge-only touch does not intersect the probe area.
      let overlap = probe.intersection(frame)
      return !overlap.isNull && !overlap.isEmpty
    }
  }
}
