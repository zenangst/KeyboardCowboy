public extension UserSpace {
  @MainActor final class Snapshot {
    public let apps: Apps

    public init(apps: Apps) {
      self.apps = apps
    }

    /// Returns a new snapshot without mutating the state held by earlier commands.
    public func refreshing(frontmost runningApplication: Core.RunningApplication?) -> Snapshot {
      let current = runningApplication.flatMap { application -> Application? in
        guard !application.isTerminated, let identifier = application.bundleIdentifier else { return nil }
        return Application(bundleIdentifier: identifier, runningApplication: application)
      }
      let oldFrontmost = apps.frontMost.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
      let oldPrevious = apps.previous.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
      let candidate: Application?
      if let current, let oldFrontmost,
         !current.runningApplication.isSameApplication(as: oldFrontmost.runningApplication) {
        candidate = oldFrontmost
      } else {
        candidate = oldPrevious
      }
      let previous = candidate.flatMap { previous in
        guard let current else { return previous }
        return previous.runningApplication.isSameApplication(as: current.runningApplication) ? nil : previous
      }
      return Snapshot(apps: .init(frontMost: current, previous: previous))
    }

    public struct Apps: Sendable {
      public let frontMost: Application?
      public let previous: Application?

      public init(frontMost: Application? = nil, previous: Application? = nil) {
        self.frontMost = frontMost
        self.previous = previous
      }
    }
  }
}
