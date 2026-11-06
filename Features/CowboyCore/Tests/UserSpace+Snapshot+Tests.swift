@testable import CowboyCore
import Testing

@Test @MainActor func snapshotCapturesFrontmostAndSuppliedHistory() {
  let frontmost = Core.RunningApplication(.testing(.init("example.front")))
  let previous = UserSpace.Application(
    bundleIdentifier: .init("example.previous"),
    runningApplication: .init(.testing(.init("example.previous"))))

  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
    let snapshot = UserSpace(.testing).takeSnapshot(previous: previous)
    #expect(snapshot.apps.frontMost?.bundleIdentifier == .init("example.front"))
    #expect(snapshot.apps.previous?.bundleIdentifier == .init("example.previous"))
  }
}

@Test @MainActor func snapshotHandlesMissingAndTerminatedApplications() {
  let previous = UserSpace.Application(
    bundleIdentifier: .init("example.previous"),
    runningApplication: .init(.testing(.init("example.previous"))))
  let frontmost = Core.RunningApplication(.testing(.init("example.front")))

  UserSpace.Testing.$mock.withValue(.init()) {
    let snapshot = UserSpace(.testing).takeSnapshot()
    #expect(snapshot.apps.frontMost == nil)
    #expect(snapshot.apps.previous == nil)
  }
  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
    Core.RunningApplication.Testing.$mock.withValue(.init(isTerminated: true)) {
      let snapshot = UserSpace(.testing).takeSnapshot(previous: previous)
      #expect(snapshot.apps.frontMost == nil)
      #expect(snapshot.apps.previous == nil)
    }
  }
}

@Test @MainActor func snapshotRefreshTracksApplicationInstances() {
  let first = Core.RunningApplication(.testing(.init("example.app")))
  let second = Core.RunningApplication(.testing(.init("example.app")))
  let oldPrevious = Core.RunningApplication(.testing(.init("example.previous")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.app"), runningApplication: first),
    previous: .init(bundleIdentifier: .init("example.previous"), runningApplication: oldPrevious)))

  let unchanged = snapshot.refreshing(frontmost: first)
  #expect(unchanged.apps.previous?.runningApplication === oldPrevious)
  let changed = unchanged.refreshing(frontmost: second)
  #expect(changed.apps.frontMost?.runningApplication === second)
  #expect(changed.apps.previous?.runningApplication === first)
  #expect(snapshot.apps.frontMost?.runningApplication === first)
  let missing = changed.refreshing(frontmost: nil)
  #expect(missing.apps.frontMost == nil)
  #expect(missing.apps.previous?.runningApplication === first)
}
