@testable import CowboyCore
import Foundation
import Testing

private final class LookupScript: @unchecked Sendable {
  private let lock = NSLock()
  private var requests: [Core.BundleIdentifier] = []
  private let application: Core.RunningApplication

  init(application: Core.RunningApplication) {
    self.application = application
  }

  func lookup(_ identifier: Core.BundleIdentifier) -> [Core.RunningApplication] {
    lock.lock()
    defer { lock.unlock() }
    requests.append(identifier)
    return requests.count == 1 ? [] : [application]
  }

  func recordedRequests() -> [Core.BundleIdentifier] {
    lock.lock()
    defer { lock.unlock() }
    return requests
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
