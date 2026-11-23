import Foundation
@testable import OpenFeature
import Testing

@Test(arguments: [0, 1, 2])
func webAppPollsAtMostTenTimesAndSkipsSingleWindow(_ count: Int) async throws {
  var events: [String] = []
  let outcome = try await Operation.WebApp.poll(initialWindowCount: count, wait: { events.append("wait") }) {
    events.append("scan")
    return false
  }
  #expect(events == (count > 1 ? Array(repeating: ["wait", "scan"], count: 10).flatMap { $0 } : []))
  #expect(outcome == (count > 1 ? .noMatch : .pollingSkipped))
}

@Test func webAppStopsPollingAfterFirstMatchingPass() async throws {
  var scans = 0
  let outcome = try await Operation.WebApp.poll(initialWindowCount: 2, wait: {}) {
    scans += 1
    return scans == 2
  }
  #expect(scans == 2)
  #expect(outcome == .raised)
}

@Test func webAppCancellationDuringWaitSkipsScan() async {
  await #expect(throws: CancellationError.self) {
    try await Operation.WebApp.poll(initialWindowCount: 2, wait: { throw CancellationError() }) {
      Issue.record("Unexpected scan after cancellation")
      return false
    }
  }
}

@Test func webAppSetsMainBeforeRaisingEachMatch() throws {
  let url = try #require(URL(string: "https://example.com/match"))
  var actions: [String] = []
  let matched = try Operation.WebApp.activateMatchingWindows(
    path: "/match",
    windows: [2, 1, 0],
    firstWebAreaURL: { $0 == 1 ? nil : url },
    setMain: { actions.append("main:\($0)") },
    raise: { actions.append("raise:\($0)") },
  )
  #expect(matched)
  #expect(actions == ["main:2", "raise:2", "main:0", "raise:0"])
}

@Test func webAppFailedMainWriteDoesNotRaise() throws {
  enum Failure: Error { case write }
  let url = try #require(URL(string: "https://example.com/match"))
  #expect(throws: Failure.write) {
    try Operation.WebApp.activateMatchingWindows(
      path: "/match", windows: [0], firstWebAreaURL: { _ in url },
      setMain: { _ in throw Failure.write },
      raise: { _ in Issue.record("Unexpected raise after failed write") },
    )
  }
}
