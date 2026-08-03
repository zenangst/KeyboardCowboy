@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testLaunchApplication() async throws {
  let launch = Operation.Launch(.testing)

  try await Core.Workspace.Testing.$mock.withValue(
    Core.Workspace.Mock(openApplication: { url, config in
      #expect(url.path() == "/tmp/foobar")
      #expect(config.activates == true)
      #expect(config.hides == false)
      return Core.RunningApplication(.testing(nil))
    }), operation: {
      try await launch(at: "/tmp/foobar", with: [])
    })
}

@Test func testLaunchApplicationBackgroundAndHidden() async throws {
  let launch = Operation.Launch(.testing)

  try await Core.Workspace.Testing.$mock.withValue(
    Core.Workspace.Mock(openApplication: { url, config in
      #expect(url.path() == "/tmp/foobar")
      #expect(config.activates == false)
      #expect(config.hides == true)
      return Core.RunningApplication(.testing(nil))
    }), operation: {
      try await launch(at: "/tmp/foobar", with: [.hidden, .background])
    })
}
