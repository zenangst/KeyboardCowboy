import CoreGraphics

public extension AppFocus {
  struct Window: Sendable {
    public let id: CGWindowID
    public let owner: pid_t
    public let ownerName: String
    public let frame: CGRect
    public let alpha: Double
    public let isOnScreen: Bool

    public init(
      id: CGWindowID, owner: pid_t, frame: CGRect, ownerName: String = "",
      alpha: Double = 1, isOnScreen: Bool = true,
    ) {
      self.id = id
      self.owner = owner
      self.frame = frame
      self.ownerName = ownerName
      self.alpha = alpha
      self.isOnScreen = isOnScreen
    }

    var isEligible: Bool {
      id != 0 && owner > 0 && isOnScreen && alpha == 1
        && !frame.isInfinite && frame.size.width > 300 && frame.size.height > 200
        && [frame.minX, frame.minY, frame.maxX, frame.maxY].allSatisfy(\.isFinite)
        && !["borders", "WindowManager", "Window Server"].contains(ownerName)
    }
  }
}
