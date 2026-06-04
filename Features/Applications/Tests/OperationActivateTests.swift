@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

let frontmostBundleIdentifier = BundleIdentifier("frontmost.me.please")
let activateBundleIdentifier = BundleIdentifier("activate.me.please")

@Test func testActivateRunningApplication() async throws {
  Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier)),
  )) {
    Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { frontmost, options in
        #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
        #expect(options == [])
        return true
      },
      bundleIdentifier: activateBundleIdentifier,
      runningApplications: [
        Core.RunningApplication(.testing(activateBundleIdentifier)),
      ],
    ),
    ) {
      let activate = Operation.Activate(.testing)
      #expect(activate(activateBundleIdentifier) == true)
    }
  }
}

@Test func testActivateFrontmostApplication() async throws {
  Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: Core.RunningApplication(.testing(frontmostBundleIdentifier)),
  )) {
    Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { frontmost, options in
        #expect(frontmost.bundleIdentifier == frontmostBundleIdentifier)
        #expect(options == [.activateAllWindows])
        return true
      },
      bundleIdentifier: frontmostBundleIdentifier,
      runningApplications: [
        Core.RunningApplication(.testing(frontmostBundleIdentifier)),
      ],
    ),
    ) {
      let activate = Operation.Activate(.testing)
      #expect(activate(activateBundleIdentifier) == true)
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
      #expect(activate(activateBundleIdentifier) == false)
    }
  }
}
