@testable import ApplicationsFeature
@testable import ApplicationSystem
import Testing

@Test func activationMatchesFrontmostIdentifierIgnoringCase() async {
  let targetID = ApplicationSystem.BundleIdentifier("com.example.editor")
  let target = ApplicationSystem.RunningApplication(.testing(targetID))
  let frontmost = ApplicationSystem.RunningApplication(.testing(.init("COM.EXAMPLE.EDITOR")))

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
        #expect(Operation.Activate(.testing)(targetID) == .activated)
      }
    }
  }
}
