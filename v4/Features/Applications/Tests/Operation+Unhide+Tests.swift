@testable import ApplicationSystem
import UserSpace
@testable import ApplicationsFeature
import Testing

@Test func testUnhideFrontmostIsNoOp() async {
  let identifier = ApplicationSystem.BundleIdentifier("frontmost.app")
  let frontmost = ApplicationSystem.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())

  await Application.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in
        Issue.record("Unhide of the frontmost app must not perform a lookup")
        return []
      },
      onUnhide: { _ in Issue.record("Frontmost app must not be unhidden"); return true },
      onActivate: { _, _ in Issue.record("Frontmost app must not be activated"); return true }
    )) {
      #expect(await Operation.Unhide(.testing)(identifier, snapshot: snapshot) == false)
    }
  }
}

@Test func testUnhideCancellationDuringLookupPreventsUnhide() async {
  let identifier = ApplicationSystem.BundleIdentifier("target.app")
  let target = ApplicationSystem.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let result = await Task {
    await Application.Workspace.Testing.$mock.withValue(.init()) {
      await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { requested in
          continuation.yield(requested == identifier ? "lookup target" : "lookup unexpected")
          withUnsafeCurrentTask { $0?.cancel() }
          return [target]
        },
        onUnhide: { _ in continuation.yield("unhide"); return true },
        onActivate: { _, _ in continuation.yield("activate"); return true }
      )) {
        await Operation.Unhide(.testing)(identifier, snapshot: snapshot)
      }
    }
  }.value
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(result == false)
  #expect(recorded == ["lookup target"])
}

@Test func testUnhideTargetsRequestedApplicationWithoutActivation() async {
  let identifier = ApplicationSystem.BundleIdentifier("target.app")
  let target = ApplicationSystem.RunningApplication(.testing(identifier))
  let frontmost = ApplicationSystem.RunningApplication(.testing(.init("frontmost.app")))
  let snapshot = await UserSpace.Snapshot(apps: .init())

  await confirmation("Expected one unhide") { unhidden in
    await Application.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
      await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
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
  let identifier = ApplicationSystem.BundleIdentifier("current.app")
  let application = ApplicationSystem.RunningApplication(.testing(identifier))
  let snapshot = await UserSpace.Snapshot(apps: .init())
  let unhide = Operation.Unhide(.testing)

  await Application.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: ApplicationSystem.RunningApplication(.testing(ApplicationSystem.BundleIdentifier("other.app")))
  )) {
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      runningApplications: [application],
      unhide: true,
    )) {
      #expect(await unhide(identifier, snapshot: snapshot) == true)
    }
  }
}

@Test func testUnhideRunnningApplication() async throws {
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
  let unhide = Operation.Unhide(.testing)

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [
      currentRunningApplication,
    ],
    unhide: true,
  ), operation: {
    #expect(await unhide(currentBundleIdentifier, snapshot: snapshot) == true)
  })
}

@Test func testUnhideFrontMostApplication() async throws {
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
  let unhide = Operation.Unhide(.testing)

  await Application.Workspace.Testing.$mock.withValue(
    Application.Workspace.Mock(frontmostApplication: currentRunningApplication),
    operation: {
      await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
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
  let unhide = Operation.Unhide(.testing)

  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [],
    unhide: true,
  ), operation: {
    #expect(await unhide(currentBundleIdentifier, snapshot: snapshot) == false)
  })
}
