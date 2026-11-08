import CowboyCore

public extension UserSpace {
  struct Application: Sendable {
    public let bundleIdentifier: Core.BundleIdentifier
    public let runningApplication: Core.RunningApplication

    public init(bundleIdentifier: Core.BundleIdentifier,
         runningApplication: Core.RunningApplication) {
      self.bundleIdentifier = bundleIdentifier
      self.runningApplication = runningApplication
    }
  }
}
