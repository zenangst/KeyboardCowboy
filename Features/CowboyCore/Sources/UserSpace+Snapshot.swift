public extension UserSpace {
  @MainActor final class Snapshot {
    public let apps: Apps

    public init(apps: Apps) {
      self.apps = apps
    }

    public struct Apps: Sendable {
      public let frontMost: Application
      public let previous: Application
    }
  }
}
