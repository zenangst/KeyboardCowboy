#if DEBUG
@testable import ApplicationsFeature
@testable import ApplicationSystem
import Commands
import Foundation
import Testing
import UserSpace

@Test @MainActor func legacyAddToStageFallsBackToOrdinaryOpen() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["addToStage","waitForAppToLaunch","hidden"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  #expect(command.modifiers == [.waitForAppToLaunch, .hidden])

  let identifier = ApplicationSystem.BundleIdentifier("example.target")
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 1, pollingInterval: .milliseconds(11), sleep: { duration in
    #expect(duration == .milliseconds(11))
    continuation.yield("wait")
  })
  let executor = Application.Executor(.testing, wait: wait)
  let initial = UserSpace.Snapshot(apps: .init())

  try await Application.Workspace.Testing.$mock.withValue(.init(openApplication: { url, configuration in
    #expect(url.path() == "/Applications/Target.app")
    #expect(configuration.activates)
    #expect(configuration.hides)
    continuation.yield("launch")
    return ApplicationSystem.RunningApplication(.testing(identifier))
  })) {
    try await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { requested in
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
#endif
