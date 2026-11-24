import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let display = WindowManagement.Display(
  bounds: CGRect(x: -900, y: -200, width: 900, height: 700),
  visibleBounds: CGRect(x: -880, y: -175, width: 860, height: 655),
)
private let original = CGRect(x: -800, y: -50, width: 400, height: 250)
private let requested = CGRect(x: -864, y: -159, width: 828, height: 623)

@Test func fillUsesSymmetricPaddingOnNegativeOriginDisplayAndReportsClamping() throws {
  let operation = try Operation.Fill(displays: [display], padding: 16)
  let observed = CGRect(origin: requested.origin, size: CGSize(width: 600, height: 450))
  var writes = 0
  let result = try #require(try operation(focusedWindow: { 1 }, frame: { _ in original }, setFrame: { target, window in
    writes += 1
    #expect(window == 1)
    #expect(target == requested)
    return observed
  }))
  #expect(writes == 1)
  #expect(result == .init(original: original, requested: requested, observed: observed))
}

@Test(arguments: [-1, CGFloat.infinity, .nan])
func fillRejectsInvalidPadding(padding: CGFloat) {
  #expect(throws: WindowManagement.FillError.invalidPadding) {
    try Operation.Fill(displays: [display], padding: padding)
  }
}

@Test func fillSkipsWritesWhenFocusChangesTargetAlreadyFillsOrPaddingLeavesNoArea() throws {
  let operation = try Operation.Fill(displays: [display], padding: 16)
  let noRoom = try Operation.Fill(displays: [display], padding: 400)
  let unexpected: (CGRect, Int) -> CGRect = { frame, _ in
    Issue.record("Unexpected frame write")
    return frame
  }

  #expect(try noRoom(focusedWindow: { 1 }, frame: { _ in original }, setFrame: unexpected) == nil)
  #expect(try operation(focusedWindow: { 1 }, frame: { _ in requested }, setFrame: unexpected)?.observed == requested)
  var focus = 0
  #expect(try operation(focusedWindow: { focus += 1; return focus }, frame: { _ in original }, setFrame: unexpected) == nil)
}

@Test func fillPropagatesFrameWriteFailureWithoutRetry() throws {
  enum Failure: Error { case write }
  let operation = try Operation.Fill(displays: [display], padding: 16)
  var writes = 0
  #expect(throws: Failure.write) {
    try operation(focusedWindow: { 1 }, frame: { _ in original }, setFrame: { _, _ in
      writes += 1
      throw Failure.write
    })
  }
  #expect(writes == 1)
}
