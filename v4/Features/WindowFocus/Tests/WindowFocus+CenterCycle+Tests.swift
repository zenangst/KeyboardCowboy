import CoreGraphics
import Testing
import WindowFocusFeature

private let display = CGRect(x: -1000, y: 100, width: 1000, height: 800)
private let visible = CGRect(x: -980, y: 150, width: 940, height: 700)
private let frame = CGRect(x: -800, y: 300, width: 500, height: 350)
private let first = WindowFocus.SpatialWindow(id: 1, frame: frame)
private let second = WindowFocus.SpatialWindow(id: 2, frame: frame)
private let third = WindowFocus.SpatialWindow(id: 3, frame: frame)

@Test func centerCyclesInCapturedOrderDespiteRaisesAndWraps() {
  var cycle = WindowFocus.CenterCycle()
  let selections: [CGWindowID?] = [
    cycle.select(in: display, visibleFrame: visible, windows: [first, second, third], focusedWindowID: 9),
    cycle.select(in: display, visibleFrame: visible, windows: [first, third, second], focusedWindowID: 1),
    cycle.select(in: display, visibleFrame: visible, windows: [second, first, third], focusedWindowID: 2),
    cycle.select(in: display, visibleFrame: visible, windows: [third, second, first], focusedWindowID: 3),
  ]
  #expect(selections == [1, 2, 3, 1])
}

@Test func centerUsesFullDisplayProbeAndStrictVisibleHorizontalInsets() {
  let leftBoundary = WindowFocus.SpatialWindow(id: 4, frame: CGRect(x: -970, y: 300, width: 500, height: 350))
  let rightBoundary = WindowFocus.SpatialWindow(id: 5, frame: CGRect(x: -600, y: 300, width: 540, height: 350))
  let edgeTouch = WindowFocus.SpatialWindow(id: 6, frame: CGRect(x: -850, y: 250, width: 400, height: 248))
  // Intersects only the legacy probe, not the display midpoint or the visible-frame midpoint.
  let offsetHit = WindowFocus.SpatialWindow(id: 7, frame: CGRect(x: -902, y: 250, width: 401, height: 249))
  let windows = [leftBoundary, rightBoundary, edgeTouch, offsetHit]
  var cycle = WindowFocus.CenterCycle()
  #expect(cycle.select(in: display, visibleFrame: visible, spacing: 10, windows: windows, focusedWindowID: 9) == 7)
  #expect(cycle.select(in: display, visibleFrame: visible, windows: windows, focusedWindowID: 9) == 4)
}

@Test func centerRetriesUnconfirmedTargetsAndSkipsVanishedWindows() {
  var cycle = WindowFocus.CenterCycle()
  #expect(cycle.select(in: display, visibleFrame: visible, windows: [first, second, third], focusedWindowID: nil) == 2)
  #expect(cycle.select(in: display, visibleFrame: visible, windows: [second, first, third], focusedWindowID: 1) == 2)
  #expect(cycle.select(in: display, visibleFrame: visible, windows: [first, third], focusedWindowID: 1) == 3)
  #expect(cycle.select(in: display, visibleFrame: visible, windows: [first], focusedWindowID: 1) == nil)
}

@Test func centerResetsOnGeometryChangeAndRejectsInvalidGeometry() {
  var cycle = WindowFocus.CenterCycle()
  #expect(cycle.select(in: display, visibleFrame: visible, windows: [first, second], focusedWindowID: 9) == 1)
  let changed = visible.insetBy(dx: 4, dy: 4)
  #expect(cycle.select(in: display, visibleFrame: changed, windows: [second, first], focusedWindowID: 9) == 2)
  #expect(cycle.select(in: display, visibleFrame: changed, spacing: .infinity,
                       windows: [first, second], focusedWindowID: 9) == nil)
  #expect(cycle.select(in: display, visibleFrame: changed, windows: [first, second], focusedWindowID: 9) == 1)
  cycle.reset()
  #expect(cycle.select(in: display, visibleFrame: changed, windows: [second, first], focusedWindowID: 9) == 2)
}
