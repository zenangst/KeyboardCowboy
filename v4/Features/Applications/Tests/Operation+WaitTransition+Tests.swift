@testable import ApplicationSystem
@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func waitTransitionsFromAbsentToUnfinishedToFinished() async throws {
  let identifier = BundleIdentifier("starting.app")
  let application = Core.RunningApplication(.testing(identifier))
  let (firstLookup, lookupResponses) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
  let (firstLaunchRead, launchResponses) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
  let (events, trace) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 3, finalSleepDuration: .milliseconds(37),
                            pollingInterval: .milliseconds(11), sleep: { duration in
    trace.yield("sleep \(duration)")
  })

  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: {
      switch launchResponses.yield(()) {
      case .enqueued: trace.yield("unfinished"); return false
      case .dropped: trace.yield("finished"); return true
      case .terminated: Issue.record("Launch responses terminated unexpectedly"); return false
      @unknown default: Issue.record("Unexpected launch response"); return false
      }
    },
    runningApplicationsLookup: { requested in
      trace.yield(requested == identifier ? "lookup target" : "lookup unexpected")
      switch lookupResponses.yield(()) {
      case .enqueued: return []
      case .dropped: return [application]
      case .terminated: Issue.record("Lookup responses terminated unexpectedly"); return []
      @unknown default: Issue.record("Unexpected lookup response"); return []
      }
    }
  )) {
    try await wait(for: identifier)
  }

  trace.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(result == .success)
  #expect(recorded == [
    "lookup target", "sleep \(Duration.milliseconds(11))",
    "lookup target", "unfinished", "sleep \(Duration.milliseconds(11))",
    "lookup target", "finished", "sleep \(Duration.milliseconds(37))",
  ])
  lookupResponses.finish()
  launchResponses.finish()
  for await _ in firstLookup {}
  for await _ in firstLaunchRead {}
}
