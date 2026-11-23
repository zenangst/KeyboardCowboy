@testable import ApplicationsFeature
@testable import ApplicationSystem
import Testing
import UserSpace

@Test func testHideUsesLiveFrontmostInsteadOfSnapshot() async {
  let targetID = ApplicationSystem.BundleIdentifier("target.app")
  let target = ApplicationSystem.RunningApplication(.testing(targetID))
  let live = ApplicationSystem.RunningApplication(.testing(.init("live.app")))
  let stale = ApplicationSystem.RunningApplication(.testing(.init("stale.app")))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("stale.app"), runningApplication: stale)))

  let (events, continuation) = AsyncStream<String>.makeStream()
  await Application.Workspace.Testing.$mock.withValue(.init(frontmostApplication: live)) {
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { identifier in
        continuation.yield(identifier == targetID ? "lookup target" : "lookup unexpected")
        return [target]
      },
      onHide: { application in
        continuation.yield(application === target ? "hide target" : "hide unexpected")
        return true
      },
      onActivate: { application, options in
        continuation.yield(application === live && options == [] ? "activate live" : "activate unexpected")
        return true
      },
    )) {
      #expect(await Operation.Hide(.testing)(targetID, snapshot: snapshot))
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["lookup target", "activate live", "hide target"])
}

@Test func testHidePreviousAlreadyHiddenIsNoOp() async {
  let previousID = ApplicationSystem.BundleIdentifier("previous.app")
  let previous = ApplicationSystem.RunningApplication(.testing(previousID))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    previous: .init(bundleIdentifier: previousID, runningApplication: previous)))

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    isHidden: true,
    runningApplicationsLookup: { _ in Issue.record("Previous wildcard must not use lookup"); return [] },
    onHide: { _ in Issue.record("Already hidden previous app must not be hidden again"); return false },
    onActivate: { _, _ in Issue.record("Already hidden previous app must not activate"); return false },
  )) {
    #expect(await Operation.Hide(.testing)(ApplicationSystem.BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot) == false)
  }
}

@Test func testHideCancellationAfterActivationPreventsHide() async {
  let identifier = ApplicationSystem.BundleIdentifier("target.app")
  let target = ApplicationSystem.RunningApplication(.testing(identifier))
  let frontmost = ApplicationSystem.RunningApplication(.testing(.init("frontmost.app")))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let result = await Task {
    await Application.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
      await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in continuation.yield("lookup"); return [target] },
        onHide: { _ in continuation.yield("hide"); return true },
        onActivate: { _, _ in
          continuation.yield("activate")
          withUnsafeCurrentTask { $0?.cancel() }
          return true
        },
      )) {
        await Operation.Hide(.testing)(identifier, snapshot: snapshot)
      }
    }
  }.value
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(result == false)
  #expect(recorded == ["lookup", "activate"])
}

@Test func testHidePreviousUsesSnapshotApplication() async {
  let previousID = ApplicationSystem.BundleIdentifier("previous.app")
  let previous = ApplicationSystem.RunningApplication(.testing(previousID))
  let snapshot = await UserSpace.Snapshot(apps: .init(
    previous: .init(bundleIdentifier: previousID, runningApplication: previous)))

  await confirmation("Expected previous application to be hidden") { hidden in
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in Issue.record("Previous wildcard must not use lookup"); return [] },
      onHide: { application in
        #expect(application === previous)
        hidden()
        return true
      },
    )) {
      _ = await Operation.Hide(.testing)(ApplicationSystem.BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot)
    }
  }
}

@Test func testHideRunnningApplication() async throws {
  let currentBundleIdentifier = ApplicationSystem.BundleIdentifier("current.app")
  let currentRunningApplication = ApplicationSystem.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = ApplicationSystem.BundleIdentifier("prev.app")
  let previousRunningApplication = ApplicationSystem.RunningApplication(.testing(previousBundleIdentifier))

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

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [
      currentRunningApplication,
    ],
  ), operation: {
    #expect(await hide(currentBundleIdentifier, snapshot: snapshot) == true)
  })
}

@Test func testHideFrontMostApplication() async throws {
  let currentBundleIdentifier = ApplicationSystem.BundleIdentifier("current.app")
  let currentRunningApplication = ApplicationSystem.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = ApplicationSystem.BundleIdentifier("prev.app")
  let previousRunningApplication = ApplicationSystem.RunningApplication(.testing(previousBundleIdentifier))

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

  await confirmation("Expected frontmost application to be reactivated") { activated in
    await Application.Workspace.Testing.$mock.withValue(
      Application.Workspace.Mock(frontmostApplication: currentRunningApplication),
      operation: {
        await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
          activate: { options in
            #expect(options == [])
            activated()
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
}

@Test func testHideNonRunnningApplication() async throws {
  let currentBundleIdentifier = ApplicationSystem.BundleIdentifier("current.app")
  let currentRunningApplication = ApplicationSystem.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = ApplicationSystem.BundleIdentifier("prev.app")
  let previousRunningApplication = ApplicationSystem.RunningApplication(.testing(previousBundleIdentifier))

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

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [],
  ), operation: {
    #expect(await hide(currentBundleIdentifier, snapshot: snapshot) == false)
  })
}

@Test func testHidePreviousWildcard() async throws {
  let currentBundleIdentifier = ApplicationSystem.BundleIdentifier("current.app")
  let currentRunningApplication = ApplicationSystem.RunningApplication(.testing(currentBundleIdentifier))

  let previousBundleIdentifier = ApplicationSystem.BundleIdentifier("prev.app")
  let previousRunningApplication = ApplicationSystem.RunningApplication(.testing(previousBundleIdentifier))

  let wildcard = ApplicationSystem.BundleIdentifier.WildCard.previous

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

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    hide: true,
    runningApplications: [],
  ), operation: {
    #expect(await hide(wildcard.bundleIdentifier, snapshot: snapshot) == false)
  })
}

@Test func testHideWithMissingSnapshotApplications() async {
  let identifier = ApplicationSystem.BundleIdentifier("current.app")
  let application = ApplicationSystem.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let hide = Operation.Hide(.testing)

  await Application.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: ApplicationSystem.RunningApplication(.testing(ApplicationSystem.BundleIdentifier("other.app"))),
  )) {
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      hide: true,
      runningApplications: [application],
    )) {
      #expect(await hide(ApplicationSystem.BundleIdentifier.WildCard.previous.bundleIdentifier, snapshot: snapshot) == false)
      #expect(await hide(identifier, snapshot: snapshot) == true)
    }
  }
}
