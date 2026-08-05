@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

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
        activate: { options in
          #expect(options == [])
          return true
        },
        runningApplications: [
          currentRunningApplication,
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
