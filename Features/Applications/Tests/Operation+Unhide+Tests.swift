@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testUnhideFrontmostIsNoOp() async {
  let identifier = BundleIdentifier("frontmost.app")
  let frontmost = Core.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in
        Issue.record("Unhide of the frontmost app must not perform a lookup")
        return []
      }
    )) {
      #expect(await Operation.Unhide(.testing)(identifier, snapshot: snapshot) == false)
    }
  }
}

@Test func testUnhideTargetsRequestedApplicationWithoutActivation() async {
  let identifier = BundleIdentifier("target.app")
  let target = Core.RunningApplication(.testing(identifier))
  let frontmost = Core.RunningApplication(.testing(.init("frontmost.app")))
  let snapshot = await UserSpace.Snapshot(apps: .init())

  await confirmation("Expected one unhide") { unhidden in
    await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        activate: { _ in Issue.record("Unexpected activation"); return false },
        runningApplications: [target],
        onUnhide: { application in
          #expect(application === target)
          unhidden()
          return true
        }
      )) {
        #expect(await Operation.Unhide(.testing)(identifier, snapshot: snapshot))
      }
    }
  }
}

@Test func testUnhideWithMissingSnapshotApplications() async {
  let identifier = BundleIdentifier("current.app")
  let application = Core.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let unhide = Operation.Unhide(.testing)

  await Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(BundleIdentifier("other.app")))
  )) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplications: [application],
      unhide: true,
    )) {
      #expect(await unhide(identifier, snapshot: snapshot) == true)
    }
  }
}

@Test func testUnhideRunnningApplication() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = BundleIdentifier("prev.app")
  let previousRunningApplication = Core.RunningApplication(.testing(previousBundleIdentifier))

  let apps = UserSpace.Snapshot.Apps(
    frontMost: .init(
      bundleIdentifier: currentBundleIdentifier,
      runningApplication: currentRunningApplication,
    ),
    previous: .init(
      bundleIdentifier: previousBundleIdentifier,
      runningApplication: previousRunningApplication,
    ))
  let snapshot = await UserSpace.Snapshot(apps: apps)
  let unhide = Operation.Unhide(.testing)

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [
      currentRunningApplication,
    ],
    unhide: true,
  ), operation: {
    #expect(await unhide(currentBundleIdentifier, snapshot: snapshot) == true)
  })
}

@Test func testUnhideFrontMostApplication() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = BundleIdentifier("prev.app")
  let previousRunningApplication = Core.RunningApplication(.testing(previousBundleIdentifier))

  let apps = UserSpace.Snapshot.Apps(
    frontMost: .init(
      bundleIdentifier: currentBundleIdentifier,
      runningApplication: currentRunningApplication,
    ),
    previous: .init(
      bundleIdentifier: previousBundleIdentifier,
      runningApplication: previousRunningApplication,
    ))
  let snapshot = await UserSpace.Snapshot(apps: apps)
  let unhide = Operation.Unhide(.testing)

  await Core.Workspace.Testing.$mock.withValue(
    Core.Workspace.Mock(frontmostApplication: currentRunningApplication),
    operation: {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        activate: { _ in
          Issue.record("Unhide must not reactivate the snapshot application")
          return false
        },
        runningApplications: [
          previousRunningApplication,
        ],
        unhide: true,
      ), operation: {
        #expect(await unhide(previousBundleIdentifier, snapshot: snapshot) == true)
      })
    })
}

@Test func testUnhideNonRunnningApplication() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = BundleIdentifier("prev.app")
  let previousRunningApplication = Core.RunningApplication(.testing(previousBundleIdentifier))

  let apps = UserSpace.Snapshot.Apps(
    frontMost: .init(
      bundleIdentifier: currentBundleIdentifier,
      runningApplication: currentRunningApplication,
    ),
    previous: .init(
      bundleIdentifier: previousBundleIdentifier,
      runningApplication: previousRunningApplication,
    ))
  let snapshot = await UserSpace.Snapshot(apps: apps)
  let unhide = Operation.Unhide(.testing)

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [],
    unhide: true,
  ), operation: {
    #expect(await unhide(currentBundleIdentifier, snapshot: snapshot) == false)
  })
}
