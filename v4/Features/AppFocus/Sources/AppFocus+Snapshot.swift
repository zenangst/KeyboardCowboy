import CoreGraphics

public extension AppFocus {
  struct Snapshot: Sendable {
    public struct Process: Equatable, Sendable {
      public let bundleIdentifier: String
      public let pid: pid_t

      public init(bundleIdentifier: String, pid: pid_t) {
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
      }
    }

    public let frontmost: Process?
    public let running: [Process]
    public let windows: [Window]
    /// Visible frames and windows use the same top-left global coordinates.
    public let displays: [CGRect]
    public let tilingMargin: CGFloat

    public init(
      frontmost: Process?, running: [Process] = [], windows: [Window] = [],
      displays: [CGRect] = [], tilingMargin: CGFloat = 0,
    ) {
      self.frontmost = frontmost
      self.running = running
      self.windows = windows
      self.displays = displays
      self.tilingMargin = tilingMargin
    }

    func eligibleWindows(of pid: pid_t) -> [Window] {
      windows.filter { $0.owner == pid && $0.isEligible }
    }
  }
}
