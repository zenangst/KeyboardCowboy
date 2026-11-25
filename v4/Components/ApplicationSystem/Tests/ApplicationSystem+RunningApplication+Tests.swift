#if DEBUG
@testable import ApplicationSystem
import Testing

@Test func runningApplicationLookupFiltersIdentifiersAndSelectsFirst() {
  let target = ApplicationSystem.BundleIdentifier("example.target")
  let other = ApplicationSystem.RunningApplication(.testing(.init("example.other")))
  let first = ApplicationSystem.RunningApplication(.testing(target))
  let second = ApplicationSystem.RunningApplication(.testing(target))
  ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(runningApplications: [other, first, second])) {
    #expect(ApplicationSystem.RunningApplication.application(with: target, env: .testing) === first)
    #expect(ApplicationSystem.RunningApplication.application(with: .init("example.missing"), env: .testing) == nil)
  }
}

@Test func runningApplicationLookupSupportsScriptedResponses() async {
  let identifier = ApplicationSystem.BundleIdentifier("example.target")
  let application = ApplicationSystem.RunningApplication(.testing(identifier))
  let (requests, requestContinuation) = AsyncStream<ApplicationSystem.BundleIdentifier>.makeStream()
  let (missing, response) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
  ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { requested in
    requestContinuation.yield(requested)
    switch response.yield(()) {
    case .enqueued: return []
    case .dropped: return [application]
    case .terminated: return []
    @unknown default: return []
    }
  })) {
    #expect(ApplicationSystem.RunningApplication.application(with: identifier, env: .testing) == nil)
    #expect(ApplicationSystem.RunningApplication.application(with: identifier, env: .testing) === application)
  }
  requestContinuation.finish()
  response.finish()
  var recorded: [ApplicationSystem.BundleIdentifier] = []
  for await request in requests { recorded.append(request) }
  var missingCount = 0
  for await _ in missing { missingCount += 1 }
  #expect(recorded == [identifier, identifier])
  #expect(missingCount == 1)
}

@Test func runningApplicationEffectMocksRecordTargetsAndResults() async {
  let first = ApplicationSystem.RunningApplication(.testing(.init("example.first")))
  let second = ApplicationSystem.RunningApplication(.testing(.init("example.second")))
  let (events, continuation) = AsyncStream<String>.makeStream()
  ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    onHide: { continuation.yield("hide:\($0.bundleIdentifier?.value ?? "missing")"); return true },
    onTerminate: { continuation.yield("terminate:\($0.bundleIdentifier?.value ?? "missing")"); return false },
    onUnhide: { continuation.yield("unhide:\($0.bundleIdentifier?.value ?? "missing")"); return true },
  )) {
    #expect(first.hide())
    #expect(!second.terminate())
    #expect(second.unhide())
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["hide:example.first", "terminate:example.second", "unhide:example.second"])
}
#endif
