@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testHideUsesLiveFrontmostInsteadOfSnapshot() async {
  let targetID = BundleIdentifier("target.app")
  let target = Core.RunningApplication(.testing(targetID))
  let live = Core.RunningApplication(.testing(.init("live.app")))
  let stale = Core.RunningApplication(.testing(.init("stale.app")))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("stale.app"), runningApplication: stale)))

  await confirmation("Expected live focus restoration") { activated in
    await confirmation("Expected target hide") { hidden in
      await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: live)) {
        await Core.RunningApplication.Testing.$mock.withValue(.init(
          runningApplications: [target],
          onHide: { application in
            #expect(application === target)
            hidden()
            return true
          },
          onActivate: { application, options in
            #expect(application === live)
            #expect(options == [])
            activated()
            return true
          }
        )) {
          #expect(await Operation.Hide(.testing)(targetID, snapshot: snapshot))
        }
      }
    }
  }
}

@Test func testHidePreviousAlreadyHiddenIsNoOp() async {
  let previousID = BundleIdentifier("previous.app")
  let previous = Core.RunningApplication(.testing(previousID))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    previous: .init(bundleIdentifier: previousID, runningApplication: previous)))

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    isHidden: true,
    onHide: { _ in Issue.record("Already hidden previous app must not be hidden again"); return false }
  )) {
    #expect(await Operation.Hide(.testing)(BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot) == false)
  }
}

@Test func testHidePreviousUsesSnapshotApplication() async {
  let previousID = BundleIdentifier("previous.app")
  let previous = Core.RunningApplication(.testing(previousID))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    previous: .init(bundleIdentifier: previousID, runningApplication: previous)))

  await confirmation("Expected previous application to be hidden") { hidden in
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in Issue.record("Previous wildcard must not use lookup"); return [] },
      onHide: { application in
        #expect(application === previous)
        hidden()
        return true
      }
    )) {
      _ = await Operation.Hide(.testing)(BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot)
    }
  }
}

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
          previousRunningApplication,
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

@Test func testHideWithMissingSnapshotApplications() async {
  let identifier = BundleIdentifier("current.app")
  let application = Core.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let hide = Operation.Hide(.testing)

  await Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(BundleIdentifier("other.app")))
  )) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      hide: true,
      runningApplications: [application],
    )) {
      #expect(await hide(BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot) == false)
      #expect(await hide(identifier, snapshot: snapshot) == true)
    }
  }
}
