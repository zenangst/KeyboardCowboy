import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let primary = WindowManagement.Display(
  bounds: CGRect(x: 0, y: 0, width: 1200, height: 800),
  visibleBounds: CGRect(x: 80, y: 25, width: 1120, height: 735),
)
private let secondary = WindowManagement.Display(
  bounds: CGRect(x: -900, y: -200, width: 900, height: 700),
  visibleBounds: CGRect(x: -900, y: -175, width: 880, height: 675),
)

@Test func centersInUsableAreaOfMostOverlappedDisplayWithoutResizing() {
  let operation = Operation.Center(displays: [primary, secondary])
  #expect(operation.requestedFrame(for: CGRect(x: 300, y: 100, width: 400, height: 200))
    == CGRect(x: 440, y: 292.5, width: 400, height: 200))
  #expect(operation.requestedFrame(for: CGRect(x: -300, y: -50, width: 400, height: 200))
    == CGRect(x: -660, y: 62.5, width: 400, height: 200))
}

@Test func keepsTopOfOversizedWindowReachableAndDoesNotGuessForOffscreenWindow() {
  let operation = Operation.Center(displays: [primary])
  #expect(operation.requestedFrame(for: CGRect(x: 300, y: -90, width: 400, height: 900))
    == CGRect(x: 440, y: 25, width: 400, height: 900))
  #expect(operation.requestedFrame(for: CGRect(x: -900, y: 0, width: 400, height: 200)) == nil)
  #expect(operation.requestedFrame(for: CGRect(x: 100, y: 100, width: -400, height: 200)) == nil)
}

@Test func movesOnlyTheOriginAndReturnsObservedClamping() throws {
  let operation = Operation.Center(displays: [primary])
  let original = CGRect(x: 300, y: 100, width: 400, height: 200)
  var observed = original
  var calls: [String] = []
  let result = try #require(try operation(
    focusedWindow: { calls.append("focus"); return 1 },
    frame: { _ in calls.append("read"); return observed },
    move: { point, window in
      calls.append("move")
      #expect(window == 1)
      #expect(point == CGPoint(x: 440, y: 292.5))
      observed.origin = CGPoint(x: point.x, y: 300)
    },
  ))
  #expect(calls == ["focus", "read", "focus", "move", "read"])
  #expect(result.original == original)
  #expect(result.requested.origin == CGPoint(x: 440, y: 292.5))
  #expect(result.observed == observed)
  #expect(result.observed.size == original.size)
}

@Test func skipsWritesForCenteredWindowOrChangedFocus() throws {
  let operation = Operation.Center(displays: [primary])
  var focused = 1
  let centered = CGRect(x: 440, y: 292.5, width: 400, height: 200)
  let unchanged = try operation(focusedWindow: { 1 }, frame: { _ in centered }, move: { _, _ in
    Issue.record("Already centered")
  })
  #expect(unchanged?.observed == centered)

  let changed = try operation(focusedWindow: { focused }, frame: { _ in
    focused = 2
    return CGRect(x: 300, y: 100, width: 400, height: 200)
  }, move: { _, _ in Issue.record("Focus changed") })
  #expect(changed == nil)
}
