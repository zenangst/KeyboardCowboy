import CoreGraphics
import Testing

@Test func exactGeometryRequiresSamePIDAndUniqueFramesOnBothSides() {
  let left = CGRect(x: -800, y: 40, width: 500, height: 300)
  let right = left.offsetBy(dx: 900, dy: 0)
  let moved = right.offsetBy(dx: 1, dy: 0)
  let windows: [GeometryEvidence.CGWindow] = [
    .init(id: 10, pid: 42, frame: left),
    .init(id: 11, pid: 23, frame: left),
    .init(id: 12, pid: 42, frame: right),
  ]
  #expect(GeometryEvidence.assess(axFrames: [left, right, moved], pid: 42, cgWindows: windows)
    == [.candidate(10), .candidate(12), .unmatched])
  #expect(GeometryEvidence.assess(axFrames: [left, left], pid: 42, cgWindows: windows)
    == [.ambiguous, .ambiguous])
  #expect(GeometryEvidence.assess(axFrames: [left], pid: 42, cgWindows: windows + [.init(id: 13, pid: 42, frame: left)])
    == [.ambiguous])
}

@Test func aUniqueCandidateCanStillBeWrongWhenSnapshotsDisagree() {
  let first = CGRect(x: 50, y: 40, width: 500, height: 300)
  let second = first.offsetBy(dx: 100, dy: 0)
  // The two actual windows swapped places between the AX and CG reads.
  let windows: [GeometryEvidence.CGWindow] = [
    .init(id: 1, pid: 42, frame: second),
    .init(id: 2, pid: 42, frame: first),
  ]
  #expect(GeometryEvidence.assess(axFrames: [first, second], pid: 42, cgWindows: windows)
    == [.candidate(2), .candidate(1)])
}
