@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func activationMatchesFrontmostIdentifierIgnoringCase() async {
  let targetID = Core.BundleIdentifier("com.example.editor")
  let target = Core.RunningApplication(.testing(targetID))
  let frontmost = Core.RunningApplication(.testing(.init("COM.EXAMPLE.EDITOR")))

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
        #expect(Operation.Activate(.testing)(targetID) == .activated)
      }
    }
  }
}
