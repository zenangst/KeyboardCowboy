import CoreGraphics

public extension WindowManagement {
  /// Bounds and usable area in AX global coordinates (top-left origin).
  struct Display: Sendable {
    public let bounds: CGRect
    public let visibleBounds: CGRect

    public init(bounds: CGRect, visibleBounds: CGRect) {
      self.bounds = bounds
      self.visibleBounds = visibleBounds
    }
  }
}
