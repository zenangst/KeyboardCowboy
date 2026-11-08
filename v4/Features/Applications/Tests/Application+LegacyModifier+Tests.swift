import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

@Test @MainActor func legacyAddToStageFallsBackToOrdinaryOpen() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["addToStage","waitForAppToLaunch","hidden"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  #expect(command.modifiers == [.waitForAppToLaunch, .hidden])

  let identifier = Core.BundleIdentifier("example.target")
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 1, pollingInterval: .milliseconds(11), sleep: { duration in
    #expect(duration == .milliseconds(11))
    continuation.yield("wait")
  })
  let executor = Application.Executor(.testing, wait: wait)
  let initial = UserSpace.Snapshot(apps: .init())

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, configuration in
    #expect(url.path() == "/Applications/Target.app")
    #expect(configuration.activates)
    #expect(configuration.hides)
    continuation.yield("launch")
    return Core.RunningApplication(.testing(identifier))
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { requested in
      #expect(requested == identifier)
      continuation.yield("lookup")
      return []
    })) {
      let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect(result !== initial)
    }
  }

  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["launch", "lookup", "lookup", "wait"])
}
