import CoreGraphics
import Testing
@testable import WindowFocusFeature

@Test func verifiedRaisePerformsOnlyTheExactTargetAfterRevalidation() throws {
  var calls: [String] = []
  let accepted = try Operation.RaiseVerifiedWindow.run(
    id: 42, windows: { ["other", "target"] },
    identity: {
      calls.append($0)
      return $0 == "target" ? 42 : 12
    },
    isCurrent: {
      calls.append("revalidate")
      return true
    },
    raise: { calls.append("raise:\($0)") },
  )
  #expect(accepted)
  #expect(calls == ["other", "target", "target", "revalidate", "raise:target"])
}

@Test func verifiedRaiseDoesNothingForMissingDuplicateStaleOrChangedIdentity() throws {
  let cases: [(count: Int, ids: [CGWindowID], current: Bool)] = [
    (1, [12], true), (2, [42, 42], true), (1, [42, 12], true), (1, [42, 42], false),
  ]
  for fixture in cases {
    var reads = 0
    let accepted = try Operation.RaiseVerifiedWindow.run(
      id: 42, windows: { Array(0 ..< fixture.count) },
      identity: { _ in
        defer { reads += 1 }
        return fixture.ids[min(reads, fixture.ids.count - 1)]
      },
      isCurrent: { fixture.current },
      raise: { _ in Issue.record("Unverified target must not be raised") },
    )
    #expect(!accepted)
  }
}

@Test func verifiedRaiseChecksCancellationAfterRevalidation() async {
  let task = Task {
    try Operation.RaiseVerifiedWindow.run(
      id: 42, windows: { [42] }, identity: { _ in 42 },
      isCurrent: {
        withUnsafeCurrentTask { $0?.cancel() }
        return true
      },
      raise: { _ in Issue.record("Cancelled target must not be raised") },
    )
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
