@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

@Test @MainActor func closingFrontmostDoesNotHideNewFrontmostAsPrevious() async throws {
  let closed = Core.RunningApplication(.testing(.init("example.closed")))
  let current = Core.RunningApplication(.testing(.init("example.current")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.closed"), runningApplication: closed),
    previous: .init(bundleIdentifier: .init("example.current"), runningApplication: current)))
  let closeFixture = #"{"application":{"bundleIdentifier":"example.closed","bundleName":"Closed","path":"/Applications/Closed.app"},"action":"close","meta":{"id":"close","name":"Close","enabled":true}}"#
  let hideFixture = #"{"application":{"bundleIdentifier":"*.*.previous","bundleName":"Previous","path":""},"action":"hide","meta":{"id":"hide","name":"Hide Previous","enabled":true}}"#
  let close = try JSONDecoder().decode(Command.Application.self, from: Data(closeFixture.utf8))
  let hide = try JSONDecoder().decode(Command.Application.self, from: Data(hideFixture.utf8))
  let executor = Application.Executor(.testing)
  let (events, continuation) = AsyncStream<String>.makeStream()

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: current)) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplications: [closed],
      onHide: { _ in Issue.record("Current app must not be hidden as previous"); return true },
      onTerminate: { application in
        #expect(application === closed)
        continuation.yield("terminate")
        return true
      },
      onIsTerminated: { $0 === closed }
    )) {
      let updated = try await executor.execute(close, cgEventType: nil, snapshot: snapshot)
      #expect(updated.apps.frontMost?.runningApplication === current)
      #expect(updated.apps.previous == nil)
      let result = try await executor.execute(hide, cgEventType: nil, snapshot: updated)
      #expect(result === updated)
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["terminate"])
}
