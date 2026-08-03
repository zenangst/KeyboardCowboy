@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testHideRunnningApplication() async throws {
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
  let hide = Operation.Hide(.testing)

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [
      currentRunningApplication,
    ],
  ), operation: {
    #expect(await hide(currentBundleIdentifier, snapshot: snapshot) == true)
  })
}

@Test func testHideFrontMostApplication() async throws {
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
  let hide = Operation.Hide(.testing)

  await Core.Workspace.Testing.$mock.withValue(
    Core.Workspace.Mock(frontmostApplication: currentRunningApplication),
    operation: {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        activate: { options in
          #expect(options == [])
          return true
        },
        hide: true,
        runningApplications: [
          currentRunningApplication,
        ],
      ), operation: {
        #expect(await hide(previousBundleIdentifier, snapshot: snapshot) == true)
      })
    })
}

@Test func testHideNonRunnningApplication() async throws {
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
  let hide = Operation.Hide(.testing)

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [],
  ), operation: {
    #expect(await hide(currentBundleIdentifier, snapshot: snapshot) == false)
  })
}

@Test func testHidePreviousWildcard() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = BundleIdentifier("prev.app")
  let previousRunningApplication = Core.RunningApplication(.testing(previousBundleIdentifier))

  let wildcard = BundleIdentifier.WildCard.previous

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
  let hide = Operation.Hide(.testing)

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [],
  ), operation: {
    #expect(await hide(wildcard.bundleIdentifier, snapshot: snapshot) == false)
  })
}
