@testable import ApplicationSystem
@testable import CowboyCore
@testable import UserSpace
import AppKit
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
  #expect(missing.apps.previous?.runningApplication === second)
}

@Test @MainActor func snapshotRefreshRetainsHistoryAcrossUnavailableFrontmost() {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let previous = Core.RunningApplication(.testing(.init("example.previous")))
  let other = Core.RunningApplication(.testing(.init("example.other")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.first"), runningApplication: first),
    previous: .init(bundleIdentifier: .init("example.previous"), runningApplication: previous)))

  let missing = snapshot.refreshing(frontmost: nil).refreshing(frontmost: nil)
  #expect(missing.apps.frontMost == nil)
  #expect(missing.apps.previous?.runningApplication === first)
  let returned = missing.refreshing(frontmost: first)
  #expect(returned.apps.frontMost?.runningApplication === first)
  #expect(returned.apps.previous?.runningApplication === previous)
  let changed = missing.refreshing(frontmost: other)
  #expect(changed.apps.frontMost?.runningApplication === other)
  #expect(changed.apps.previous?.runningApplication === first)

  Core.RunningApplication.Testing.$mock.withValue(.init(onIsTerminated: { $0 === first })) {
    let filtered = missing.refreshing(frontmost: nil)
    #expect(filtered.apps.previous?.runningApplication === previous)
    let changed = filtered.refreshing(frontmost: other)
    #expect(changed.apps.previous?.runningApplication === previous)
  }
}

@Test @MainActor func snapshotTracksActivationHistoryAndRemovesTerminatedEntries() {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let current = Core.RunningApplication(.testing(.init("example.current")))
  let userSpace = UserSpace(.testing)
  userSpace.recordActivation(first)
  userSpace.recordActivation(second)
  userSpace.recordActivation(current)

  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: current)) {
    let snapshot = userSpace.takeSnapshot()
    #expect(snapshot.apps.frontMost?.runningApplication === current)
    #expect(snapshot.apps.previous?.runningApplication === second)
    let repeated = userSpace.takeSnapshot()
    #expect(repeated.apps.previous?.runningApplication === second)

    Core.RunningApplication.Testing.$mock.withValue(.init(onIsTerminated: { $0 === second })) {
      let filtered = userSpace.takeSnapshot()
      #expect(filtered.apps.frontMost?.runningApplication === current)
      #expect(filtered.apps.previous?.runningApplication === first)
    }
  }
}

@Test @MainActor func snapshotsTrackObservedFrontmostTransitions() {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let userSpace = UserSpace(.testing)

  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: first)) {
    let snapshot = userSpace.takeSnapshot()
    #expect(snapshot.apps.frontMost?.runningApplication === first)
    #expect(snapshot.apps.previous == nil)
  }
  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: second)) {
    let snapshot = userSpace.takeSnapshot()
    #expect(snapshot.apps.frontMost?.runningApplication === second)
    #expect(snapshot.apps.previous?.runningApplication === first)
  }
  UserSpace.Testing.$mock.withValue(.init(frontmostApplication: first)) {
    let snapshot = userSpace.takeSnapshot()
    #expect(snapshot.apps.frontMost?.runningApplication === first)
    #expect(snapshot.apps.previous?.runningApplication === second)
  }
}

@Test @MainActor func snapshotUsesRecentHistoryWhenFrontmostIsUnavailable() {
  let previous = Core.RunningApplication(.testing(.init("example.previous")))
  let userSpace = UserSpace(.testing)
  userSpace.recordActivation(previous)
  UserSpace.Testing.$mock.withValue(.init()) {
    let snapshot = userSpace.takeSnapshot()
    #expect(snapshot.apps.frontMost == nil)
    #expect(snapshot.apps.previous?.runningApplication === previous)
  }
}

@Test @MainActor func snapshotRefreshFiltersIndependentlyTerminatedHistory() {
  let current = Core.RunningApplication(.testing(.init("example.current")))
  let previous = Core.RunningApplication(.testing(.init("example.previous")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.current"), runningApplication: current),
    previous: .init(bundleIdentifier: .init("example.previous"), runningApplication: previous)))

  Core.RunningApplication.Testing.$mock.withValue(.init(onIsTerminated: { $0 === previous })) {
    let refreshed = snapshot.refreshing(frontmost: current)
    #expect(refreshed.apps.frontMost?.runningApplication === current)
    #expect(refreshed.apps.previous == nil)
  }
}

@Test @MainActor func snapshotRefreshDoesNotReuseCurrentAppAsPreviousAfterTermination() {
  let closed = Core.RunningApplication(.testing(.init("example.closed")))
  let current = Core.RunningApplication(.testing(.init("example.current")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.closed"), runningApplication: closed),
    previous: .init(bundleIdentifier: .init("example.current"), runningApplication: current)))

  Core.RunningApplication.Testing.$mock.withValue(.init(onIsTerminated: { $0 === closed })) {
    let updated = snapshot.refreshing(frontmost: current)
    #expect(updated.apps.frontMost?.runningApplication === current)
    #expect(updated.apps.previous == nil)
  }
}

@Test @MainActor func productionSnapshotNeverUsesTestingApplication() {
  let snapshot = UserSpace(.production).takeSnapshot()
  if let application = snapshot.apps.frontMost?.runningApplication {
    guard case .production = application.mode else {
      Issue.record("Production snapshot contained a testing application")
      return
    }
  }
  if let application = snapshot.apps.previous?.runningApplication {
    guard case .production = application.mode else {
      Issue.record("Production history contained a testing application")
      return
    }
  }
}
