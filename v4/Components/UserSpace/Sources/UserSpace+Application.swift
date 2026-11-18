import ApplicationSystem

public extension UserSpace {
  struct Application: Sendable {
    public let bundleIdentifier: ApplicationSystem.BundleIdentifier
    public let runningApplication: ApplicationSystem.RunningApplication

    public init(bundleIdentifier: ApplicationSystem.BundleIdentifier,
                runningApplication: ApplicationSystem.RunningApplication) {
      self.bundleIdentifier = bundleIdentifier
      self.runningApplication = runningApplication
    }
  }
}
