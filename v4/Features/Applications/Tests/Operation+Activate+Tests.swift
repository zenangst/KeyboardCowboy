@testable import ApplicationSystem
@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

let frontmostBundleIdentifier = BundleIdentifier("frontmost.me.please")
let activateBundleIdentifier = BundleIdentifier("activate.me.please")

@Test func testActivateRunningApplication() async throws {
  await confirmation("Expected one activation") { activated in
    Core.Workspace.Testing.$mock.withValue(.init(
      frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier)),
    )) {
      Core.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { frontmost, options in
          #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
          #expect(options == [])
          activated()
          return true
        },
        bundleIdentifier: activateBundleIdentifier,
        runningApplications: [
          Core.RunningApplication(.testing(activateBundleIdentifier)),
        ],
      ),
      ) {
        let activate = Operation.Activate(.testing)
        #expect(activate(activateBundleIdentifier) == .activated)
      }
    }
  }
}

@Test func testActivateFrontmostApplication() async throws {
  await confirmation("Expected one activation") { activated in
    Core.Workspace.Testing.$mock.withValue(.init(
      frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier)),
    )) {
      Core.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { frontmost, options in
          #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
          #expect(options == [.activateAllWindows])
          activated()
          return true
        },
        bundleIdentifier: frontmostBundleIdentifier,
        runningApplications: [
          Core.RunningApplication(.testing(frontmostBundleIdentifier)),
        ],
      ),
      ) {
        let activate = Operation.Activate(.testing)
        #expect(activate(frontmostBundleIdentifier) == .activated)
      }
    }
  }
}

@Test func testActivateFrontmostIdentifierComparisonIgnoresCase() async {
  let requested = BundleIdentifier("com.example.editor")
  let frontmost = Core.RunningApplication(.testing(.init("COM.Example.Editor")))
  let target = Core.RunningApplication(.testing(requested))
  await confirmation("Expected all-windows activation") { activated in
    Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
      Core.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { application, options in
          #expect(application === frontmost)
          #expect(options == [.activateAllWindows])
          activated()
          return true
        },
        runningApplications: [target]
      )) {
        #expect(Operation.Activate(.testing)(requested) == .activated)
      }
    }
  }
}

@Test func testActivateNonRunningApplication() async throws {
  Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier)),
  )) {
    Core.RunningApplication.Testing.$mock.withValue(.init(
      bundleIdentifier: frontmostBundleIdentifier,
      runningApplications: [],
    ),
    ) {
      let activate = Operation.Activate(.testing)
      #expect(activate(activateBundleIdentifier) == .missingTarget)
    }
  }
}

@Test func testActivateReportsMissingFrontmostAndRejection() {
  let activate = Operation.Activate(.testing)
  Core.Workspace.Testing.$mock.withValue(.init()) {
    #expect(activate(activateBundleIdentifier) == .missingFrontmost)
  }
  Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier))
  )) {
    Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in false },
      runningApplications: [.init(.testing(activateBundleIdentifier))]
    )) {
      #expect(activate(activateBundleIdentifier) == .rejected)
    }
  }
}

@Test func testActivateCancellationDuringLookupPreventsActivation() async {
  let target = Core.RunningApplication(.testing(activateBundleIdentifier))
  let result = await withTaskGroup(of: Operation.Activate.Result.self, returning: Operation.Activate.Result.self) { group in
    group.addTask {
      Core.Workspace.Testing.$mock.withValue(.init(
        frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier))
      )) {
        Core.RunningApplication.Testing.$mock.withValue(.init(
          activateFrom: { _, _ in Issue.record("Cancelled lookup must not activate"); return false },
          runningApplicationsLookup: { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return [target]
          }
        )) {
          Operation.Activate(.testing)(activateBundleIdentifier)
        }
      }
    }
    return await group.next() ?? .rejected
  }
  #expect(result == .cancelled)
}
