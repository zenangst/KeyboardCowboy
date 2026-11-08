import CowboyCore

public extension UserSpace {
  @MainActor final class Snapshot {
    public let apps: Apps
    private let lastFrontmost: Application?
    private let lastPrevious: Application?

    public init(apps: Apps) {
      self.apps = apps
      self.lastFrontmost = apps.frontMost
      self.lastPrevious = apps.previous
    }

    private init(apps: Apps, lastFrontmost: Application?, lastPrevious: Application?) {
      self.apps = apps
      self.lastFrontmost = lastFrontmost
      self.lastPrevious = lastPrevious
    }

    /// Returns a new snapshot without mutating the state held by earlier commands.
    public func refreshing(frontmost runningApplication: Core.RunningApplication?) -> Snapshot {
      let current = runningApplication.flatMap { application -> Application? in
        guard !application.isTerminated, let identifier = application.bundleIdentifier else { return nil }
        return Application(bundleIdentifier: identifier, runningApplication: application)
      }
      let oldFrontmost = lastFrontmost.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
      let oldPrevious = lastPrevious.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
      guard let current else {
        return Snapshot(
          apps: .init(frontMost: nil, previous: oldFrontmost ?? oldPrevious),
          lastFrontmost: oldFrontmost, lastPrevious: oldPrevious)
      }
      let candidate: Application?
      if let oldFrontmost,
         !current.runningApplication.isSameApplication(as: oldFrontmost.runningApplication) {
        candidate = oldFrontmost
      } else {
        candidate = oldPrevious
      }
      let previous = candidate.flatMap { previous in
        return previous.runningApplication.isSameApplication(as: current.runningApplication) ? nil : previous
      }
      return Snapshot(apps: .init(frontMost: current, previous: previous),
                      lastFrontmost: current, lastPrevious: previous)
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
