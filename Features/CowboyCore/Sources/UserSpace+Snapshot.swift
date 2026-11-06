public extension UserSpace {
  @MainActor final class Snapshot {
    public let apps: Apps

    public init(apps: Apps) {
      self.apps = apps
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
