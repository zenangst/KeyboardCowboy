#if DEBUG
@testable import HostInput
import Testing

@Test func missingWindowIDBridgeDoesNotReadGraphics() {
  let result = HostInput.checkWindowIDs(nil, expectedPID: 42) {
    Issue.record("An unavailable bridge must not read Core Graphics")
    return [:]
  }
  #expect(result == .bridgeUnavailable)
}

@Test func unavailableGraphicsSnapshotIsNotAnEmptySnapshot() {
  #expect(HostInput.checkWindowIDs([11], expectedPID: 42, owners: { nil }) == .snapshotUnavailable)
  #expect(HostInput.checkWindowIDs([11], expectedPID: 42, owners: { [:] }) == .checked(.init(absent: 1)))
}

@Test func checksWindowIDsAgainstFreshGraphicsOwnershipWithoutGuessing() {
  var snapshots = 0
  let result = HostInput.checkWindowIDs([11, nil, 0, 12, 13, 14], expectedPID: 42) {
    snapshots += 1
    return [11: [42], 12: [99], 14: [42, 99]]
  }
  #expect(snapshots == 1)
  #expect(result == .checked(.init(matched: 1, lookupMisses: 2, absent: 1, wrongOwner: 2)))
}
#endif
