@testable import CowboyCore
import os
import Testing

private final class LookupScript: Sendable {
  private let requests = OSAllocatedUnfairLock(initialState: [Core.BundleIdentifier]())
  private let application: Core.RunningApplication

  init(application: Core.RunningApplication) {
    self.application = application
  }

  func lookup(_ identifier: Core.BundleIdentifier) -> [Core.RunningApplication] {
    requests.withLock { requests in
      requests.append(identifier)
      return requests.count == 1 ? [] : [application]
    }
  }

  func recordedRequests() -> [Core.BundleIdentifier] {
    requests.withLock { $0 }
  }
}

private final class EffectRecorder: Sendable {
  private let events = OSAllocatedUnfairLock(initialState: [String]())

  func record(_ action: String, application: Core.RunningApplication) -> Bool {
    let event = "\(action):\(application.bundleIdentifier?.value ?? "missing")"
    events.withLock { $0.append(event) }
    return action != "terminate"
  }

  func recordedEvents() -> [String] {
    events.withLock { $0 }
  }
}

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

@Test func runningApplicationLookupSupportsScriptedResponses() {
  let identifier = Core.BundleIdentifier("example.target")
  let application = Core.RunningApplication(.testing(identifier))
  let script = LookupScript(application: application)
  Core.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: script.lookup)) {
    #expect(Core.RunningApplication.application(with: identifier, env: .testing) == nil)
    #expect(Core.RunningApplication.application(with: identifier, env: .testing) === application)
  }
  #expect(script.recordedRequests() == [identifier, identifier])
}

@Test func runningApplicationEffectMocksRecordTargetsAndResults() {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let recorder = EffectRecorder()
  Core.RunningApplication.Testing.$mock.withValue(.init(
    onHide: { recorder.record("hide", application: $0) },
    onTerminate: { recorder.record("terminate", application: $0) },
    onUnhide: { recorder.record("unhide", application: $0) }
  )) {
    #expect(first.hide())
    #expect(!second.terminate())
    #expect(second.unhide())
  }
  #expect(recorder.recordedEvents() == ["hide:example.first", "terminate:example.second", "unhide:example.second"])
}
