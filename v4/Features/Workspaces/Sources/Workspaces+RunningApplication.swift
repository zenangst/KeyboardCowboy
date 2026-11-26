public extension Workspaces {
  struct RunningApplication: Sendable {
    public let pid: Int32
    public let bundleIdentifier: String?
    public let isHidden: Bool
    public let isFinishedLaunching: Bool

    public init(pid: Int32, bundleIdentifier: String?, isHidden: Bool, isFinishedLaunching: Bool) {
      self.pid = pid
      self.bundleIdentifier = bundleIdentifier
      self.isHidden = isHidden
      self.isFinishedLaunching = isFinishedLaunching
    }
  }
}
