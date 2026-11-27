import CoreGraphics

public extension WindowFocus.SpaceRing {
  struct Window: Equatable, Sendable {
    public let id: CGWindowID
    public let owner: pid_t
    public let frame: CGRect
    public let alpha: Double
    public let isOnScreen: Bool
    public let ownerName: String

    public init(
      id: CGWindowID, owner: pid_t, frame: CGRect, alpha: Double = 1,
      isOnScreen: Bool = true, ownerName: String = "",
    ) {
      self.id = id
      self.owner = owner
      self.frame = frame
      self.alpha = alpha
      self.isOnScreen = isOnScreen
      self.ownerName = ownerName
    }

    var isEligible: Bool {
      id != 0 && owner > 0 && isOnScreen && alpha.isFinite && alpha > 0
        && WindowFocus.SpatialWindow.isValid(frame) && frame.width > 100 && frame.height > 100
        && !["borders", "WindowManager", "Window Server"].contains(ownerName)
    }

    var spatialWindow: WindowFocus.SpatialWindow { .init(id: id, frame: frame) }

    var isSpatiallyEligible: Bool { isEligible && alpha == 1 && frame.width > 300 && frame.height > 200 }
  }
}
