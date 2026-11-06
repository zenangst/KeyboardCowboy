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

@Test func testLaunchCancellationTakesPrecedenceOverOpenError() async {
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
        withUnsafeCurrentTask { $0?.cancel() }
        throw LaunchError.failed
      })) {
        do {
          try await Operation.Launch(.testing)(at: "/tmp/foobar", with: [])
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
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

@Test func testLaunchReportsCancellationAfterOpenReturns() async {
  let recorder = LaunchRecorder()
  let cancelled = await Task {
    await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
      await recorder.record(url.path())
      withUnsafeCurrentTask { $0?.cancel() }
      return Core.RunningApplication(.testing(nil))
    })) {
      do {
        try await Operation.Launch(.testing)(at: "/tmp/foobar", with: [])
        return false
      } catch is CancellationError {
        return true
      } catch {
        return false
      }
    }
  }.value
  #expect(cancelled)
  #expect(await recorder.paths == ["/tmp/foobar"])
}

@Test func testLaunchApplication() async throws {
  let launch = Operation.Launch(.testing)

  try await confirmation("Expected one open") { opened in
    try await Core.Workspace.Testing.$mock.withValue(
      Core.Workspace.Mock(openApplication: { url, config in
        #expect(url.path() == "/tmp/foobar")
        #expect(config.activates == true)
        #expect(config.hides == false)
        opened()
        return Core.RunningApplication(.testing(nil))
      }), operation: {
        try await launch(at: "/tmp/foobar", with: [])
      })
  }
}

@Test func testLaunchApplicationBackgroundAndHidden() async throws {
  let launch = Operation.Launch(.testing)

  try await confirmation("Expected one background open") { opened in
    try await Core.Workspace.Testing.$mock.withValue(
      Core.Workspace.Mock(openApplication: { url, config in
        #expect(url.path() == "/tmp/foobar")
        #expect(config.activates == false)
        #expect(config.hides == true)
        opened()
        return Core.RunningApplication(.testing(nil))
      }), operation: {
        try await launch(at: "/tmp/foobar", with: [.hidden, .background])
      })
  }
}
