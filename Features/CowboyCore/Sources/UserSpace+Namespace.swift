import Apps
import Cocoa

@MainActor
public final class UserSpace {
  let env: Core.Environment

  init(_ env: Core.Environment) {
    self.env = env
  }

  func takeSnapshot() -> Snapshot {
    #if DEBUG
    Snapshot(
      apps: Snapshot.Apps(
        frontMost: Application(bundleIdentifier: .init(""),
                               runningApplication: .init(.testing(nil))),
        previous: Application(bundleIdentifier: .init(""),
                              runningApplication: .init(.testing(nil)))))
    #else
    // Snapshot collection is still a placeholder; Release must not use testing applications.
    Snapshot(
      apps: Snapshot.Apps(
        frontMost: Application(bundleIdentifier: .init(""),
                               runningApplication: .init(.production(.current))),
        previous: Application(bundleIdentifier: .init(""),
                              runningApplication: .init(.production(.current)))))
    #endif
  }
}
