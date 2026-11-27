import ApplicationCatalog

public extension Workspaces {
  struct FocusState: Sendable {
    public let menuBarOwner: String?
    public let runningBundleIdentifiers: Set<String>

    public init(menuBarOwner: String?, runningBundleIdentifiers: Set<String>) {
      self.menuBarOwner = menuBarOwner
      self.runningBundleIdentifiers = runningBundleIdentifiers
    }
  }
}

extension Workspaces.SavedWorkspace {
  func focusFallback(
    catalog: [ApplicationCatalog.Application], state: Workspaces.FocusState, awaitedApplications: Set<String>,
  ) -> Workspaces.Step? {
    guard let owner = state.menuBarOwner, !awaitedApplications.contains(owner),
          let last = applications.last(where: {
            !$0.onlyWhenRunning || state.runningBundleIdentifiers.contains($0.bundleIdentifier)
          }),
          let application = catalog.first(where: { $0.bundleIdentifier == last.bundleIdentifier }) else { return nil }

    return .application(.init(application: application, name: "", action: .open, modifiers: []))
  }
}
