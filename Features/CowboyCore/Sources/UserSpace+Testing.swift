#if DEBUG
extension UserSpace {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    let apps: Snapshot.Apps

    init(apps: Snapshot.Apps = Snapshot.Apps(
      frontMost: Application(bundleIdentifier: .init(""),
                             runningApplication: .init(.testing(nil))),
      previous: Application(bundleIdentifier: .init(""),
                            runningApplication: .init(.testing(nil))),
    ),
    ) {
      self.apps = apps
    }
  }
}
#endif
