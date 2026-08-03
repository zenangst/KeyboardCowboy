@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testHideApplication() async throws {
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
