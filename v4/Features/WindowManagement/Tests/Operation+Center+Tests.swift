import CoreGraphics
import Foundation
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

@Test func centerToggleRestoresOnlyTheMatchingUnchangedWindow() throws {
  let operation = Operation.Center(displays: [secondary])
  let launch = Date(timeIntervalSince1970: 100)
  let original = CGRect(x: -800, y: -50, width: 400, height: 200)
  let centered = try #require(operation.requestedFrame(for: original))
  let point = WindowManagement.CenterRestorePoint(pid: 42, launchDate: launch, id: 12, original: original, centered: centered)
  func target(
    pid: pid_t = 42, launched: Date? = launch, id: CGWindowID = 12, frame: CGRect = centered, cg: CGRect? = nil,
  ) -> WindowManagement.PlacementRequest? {
    operation.togglePlacement(in: pid, launchDate: launched, id: id, current: frame, onScreen: cg ?? frame, point: point)
  }
  #expect(target() == .restore(original))
  #expect(target(frame: centered.offsetBy(dx: 0, dy: 0.5)) == .restore(original))
  #expect(target(pid: 43) == .place(centered))
  #expect(target(launched: nil) == .place(centered))
  #expect(target(launched: launch + 1) == .place(centered))
  #expect(target(id: 13) == .place(centered))
  #expect(target(frame: original) == .place(centered))
  #expect(target(cg: centered.offsetBy(dx: 4, dy: 0)) == nil)
  let resized = centered.insetBy(dx: 20, dy: 0)
  #expect(target(frame: resized) == .place(resized))
}
