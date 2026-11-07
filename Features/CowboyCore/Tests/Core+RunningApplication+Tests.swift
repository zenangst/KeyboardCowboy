@testable import CowboyCore
import Testing

@Test func runningApplicationLookupFiltersIdentifiersAndSelectsFirst() {
  let target = Core.BundleIdentifier("example.target")
  let other = Core.RunningApplication(.testing(.init("example.other")))
  let first = Core.RunningApplication(.testing(target))
  let second = Core.RunningApplication(.testing(target))
  Core.RunningApplication.Testing.$mock.withValue(.init(runningApplications: [other, first, second])) {
    #expect(Core.RunningApplication.application(with: target, env: .testing) === first)
    #expect(Core.RunningApplication.application(with: .init("example.missing"), env: .testing) == nil)
  }
}

@Test func runningApplicationLookupSupportsScriptedResponses() async {
  let identifier = Core.BundleIdentifier("example.target")
  let application = Core.RunningApplication(.testing(identifier))
  let (requests, requestContinuation) = AsyncStream<Core.BundleIdentifier>.makeStream()
  let (missing, response) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
  Core.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { requested in
    requestContinuation.yield(requested)
    switch response.yield(()) {
    case .enqueued: return []
    case .dropped: return [application]
    case .terminated: return []
    @unknown default: return []
    }
  })) {
    #expect(Core.RunningApplication.application(with: identifier, env: .testing) == nil)
    #expect(Core.RunningApplication.application(with: identifier, env: .testing) === application)
  }
  requestContinuation.finish()
  response.finish()
  var recorded: [Core.BundleIdentifier] = []
  for await request in requests { recorded.append(request) }
  var missingCount = 0
  for await _ in missing { missingCount += 1 }
  #expect(recorded == [identifier, identifier])
  #expect(missingCount == 1)
}

@Test func runningApplicationEffectMocksRecordTargetsAndResults() async {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let (events, continuation) = AsyncStream<String>.makeStream()
  Core.RunningApplication.Testing.$mock.withValue(.init(
    onHide: { continuation.yield("hide:\($0.bundleIdentifier?.value ?? "missing")"); return true },
    onTerminate: { continuation.yield("terminate:\($0.bundleIdentifier?.value ?? "missing")"); return false },
    onUnhide: { continuation.yield("unhide:\($0.bundleIdentifier?.value ?? "missing")"); return true }
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
