import ApplicationCatalog

public extension Workspaces {
  struct ActivationInput: Sendable {
    public let catalog: [ApplicationCatalog.Application]
    public let runningApplications: [RunningApplication]
    public let windows: [Window]
    public let frontmostBundleIdentifier: String?
    public let membership: Membership
    public let stageManagerEnabled: Bool

    public init(
      catalog: [ApplicationCatalog.Application],
      runningApplications: [RunningApplication] = [],
      windows: [Window] = [],
      frontmostBundleIdentifier: String? = nil,
      membership: Membership = .init(),
      stageManagerEnabled: Bool = false,
    ) {
      self.catalog = catalog
      self.runningApplications = runningApplications
      self.windows = windows
      self.frontmostBundleIdentifier = frontmostBundleIdentifier
      self.membership = membership
      self.stageManagerEnabled = stageManagerEnabled
    }
  }
}
