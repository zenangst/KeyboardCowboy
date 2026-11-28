#if DEBUG
@testable import ApplicationsFeature
@testable import ApplicationSystem
import Testing

let frontmostBundleIdentifier = ApplicationSystem.BundleIdentifier("frontmost.me.please")
let activateBundleIdentifier = ApplicationSystem.BundleIdentifier("activate.me.please")

@Test func testActivateRunningApplication() async throws {
  await confirmation("Expected one activation") { activated in
    Application.Workspace.Testing.$mock.withValue(.init(
      frontmostApplication: ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
    )) {
      ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { frontmost, options in
          #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
          #expect(options == [])
          activated()
          return true
        },
        bundleIdentifier: activateBundleIdentifier,
        runningApplications: [
          ApplicationSystem.RunningApplication(.testing(activateBundleIdentifier)),
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
    Application.Workspace.Testing.$mock.withValue(.init(
      frontmostApplication: ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
    )) {
      ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { frontmost, options in
          #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
          #expect(options == [.activateAllWindows])
          activated()
          return true
        },
        bundleIdentifier: frontmostBundleIdentifier,
        runningApplications: [
          ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
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
  let requested = ApplicationSystem.BundleIdentifier("com.example.editor")
  let frontmost = ApplicationSystem.RunningApplication(.testing(.init("COM.Example.Editor")))
  let target = ApplicationSystem.RunningApplication(.testing(requested))
  await confirmation("Expected all-windows activation") { activated in
    Application.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
      ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
        activateFrom: { application, options in
          #expect(application === frontmost)
          #expect(options == [.activateAllWindows])
          activated()
          return true
        },
        runningApplications: [target],
      )) {
        #expect(Operation.Activate(.testing)(requested) == .activated)
      }
    }
  }
}

@Test func testActivateNonRunningApplication() async throws {
  Application.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
  )) {
    ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
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
  Application.Workspace.Testing.$mock.withValue(.init()) {
    #expect(activate(activateBundleIdentifier) == .missingFrontmost)
  }
  Application.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
  )) {
    ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in false },
      runningApplications: [.init(.testing(activateBundleIdentifier))],
    )) {
      #expect(activate(activateBundleIdentifier) == .rejected)
    }
  }
}

@Test func testActivateCancellationDuringLookupPreventsActivation() async {
  let target = ApplicationSystem.RunningApplication(.testing(activateBundleIdentifier))
  let result = await withTaskGroup(of: Operation.Activate.Result.self, returning: Operation.Activate.Result.self) { group in
    group.addTask {
      Application.Workspace.Testing.$mock.withValue(.init(
        frontmostApplication: ApplicationSystem.RunningApplication(.testing(frontmostBundleIdentifier)),
      )) {
        ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
          activateFrom: { _, _ in Issue.record("Cancelled lookup must not activate"); return false },
          runningApplicationsLookup: { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return [target]
          },
        )) {
          Operation.Activate(.testing)(activateBundleIdentifier)
        }
      }
    }
    return await group.next() ?? .rejected
  }
  #expect(result == .cancelled)
}
#endif
