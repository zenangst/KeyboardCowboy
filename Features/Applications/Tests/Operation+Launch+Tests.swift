@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

private actor LaunchRecorder {
  private(set) var paths: [String] = []
  func record(_ path: String) { paths.append(path) }
}

private enum LaunchError: Error {
  case failed
}

@Test func testLaunchPropagatesAsyncFailure() async {
  let recorder = LaunchRecorder()
  let launch = Operation.Launch(.testing)

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
    await recorder.record(url.path())
    await Task.yield()
    throw LaunchError.failed
  })) {
    await #expect(throws: LaunchError.failed) {
      try await launch(at: "/tmp/foobar", with: [])
    }
  }
  #expect(await recorder.paths == ["/tmp/foobar"])
}

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
