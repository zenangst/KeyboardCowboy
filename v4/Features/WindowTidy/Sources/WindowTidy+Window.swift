import CoreGraphics

public extension WindowTidy {
  struct Window: Equatable, Sendable {
    public let id: CGWindowID
    public let owner: pid_t
    public let bundleIdentifier: String?
    public let frame: CGRect
    public let ownerName: String
    public let alpha: Double
    public let isOnScreen: Bool

    public init(
      id: CGWindowID, owner: pid_t, frame: CGRect, bundleIdentifier: String? = nil,
      ownerName: String = "", alpha: Double = 1, isOnScreen: Bool = true,
    ) {
      self.id = id
      self.owner = owner
      self.frame = frame
      self.bundleIdentifier = bundleIdentifier
      self.ownerName = ownerName
      self.alpha = alpha
      self.isOnScreen = isOnScreen
    }

    var isEligible: Bool {
      id != 0 && owner > 0 && isOnScreen && alpha.isFinite && alpha > 0
        && WindowTidy.valid(frame) && frame.width > 300 && frame.height > 200
        && !["borders", "WindowManager", "Window Server"].contains(ownerName)
    }
  }
}
