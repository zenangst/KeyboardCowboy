import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Cycle = WindowFocus.QuarterCycle
private let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
private let topLeft = CGRect(x: 20, y: 20, width: 350, height: 250)

@Test func topLeftDoublePressReachesAnOccludedWindowAndWrapsDespiteRaises() {
  var cycle = Cycle()
  let first = Cycle.Window(id: 1, frame: topLeft)
  let behind = Cycle.Window(id: 2, frame: topLeft)
  let partial = Cycle.Window(id: 3, frame: CGRect(x: 90, y: 100, width: 350, height: 250))
  let outside = Cycle.Window(id: 4, frame: CGRect(x: 101, y: 20, width: 350, height: 250))

  #expect(cycle.select(.topLeft, in: display, windows: [outside, first, behind, partial], focusedWindowID: 4) == 1)
  #expect(cycle.select(.topLeft, in: display, windows: [first, outside, behind, partial], focusedWindowID: 1) == 2)
  #expect(cycle.select(.topLeft, in: display, windows: [behind, first, outside, partial], focusedWindowID: 2) == 3)
  #expect(cycle.select(.topLeft, in: display, windows: [partial, behind, first, outside], focusedWindowID: 3) == 1)
  #expect(cycle.select(.topLeft, in: display, windows: [first, partial, behind, outside], focusedWindowID: 1) == 2)
}

@Test func switchingQuarterOrResetRestartsTheCycleInCurrentStackOrder() {
  var cycle = Cycle()
  let first = Cycle.Window(id: 1, frame: topLeft)
  let second = Cycle.Window(id: 2, frame: topLeft)
  let right = Cycle.Window(id: 3, frame: CGRect(x: 620, y: 20, width: 350, height: 250))
  let outside = Cycle.Window(id: 4, frame: CGRect(x: 300, y: 400, width: 350, height: 250))
  let initial = [first, second, right, outside]
  let reordered = [second, first, right, outside]

  #expect(cycle.select(.topLeft, in: display, windows: initial, focusedWindowID: 4) == 1)
  #expect(cycle.select(.topRight, in: display, windows: reordered, focusedWindowID: 1) == 3)
  #expect(cycle.select(.topLeft, in: display, windows: reordered, focusedWindowID: 3) == 2)
  cycle.reset()
  #expect(cycle.select(.topLeft, in: display, windows: initial, focusedWindowID: 3) == 1)
}

@Test func onlyConfirmedFocusConsumesACandidateAndVanishedWindowsAreSkipped() {
  var cycle = Cycle()
  let first = Cycle.Window(id: 1, frame: topLeft)
  let removed = Cycle.Window(id: 2, frame: topLeft)
  let next = Cycle.Window(id: 3, frame: topLeft)
  let new = Cycle.Window(id: 4, frame: topLeft)

  #expect(cycle.select(.topLeft, in: display, windows: [first, removed, next], focusedWindowID: 1) == 2)
  #expect(cycle.select(.topLeft, in: display, windows: [first, removed, next], focusedWindowID: 1) == 2)
  #expect(cycle.select(.topLeft, in: display, windows: [new, first, next], focusedWindowID: 1) == 3)
  #expect(cycle.select(.topLeft, in: display, windows: [next, first, new], focusedWindowID: 3) == 4)
}

@Test func noAlternativeDoesNotReselectActiveOrAnEdgeOnlyWindow() {
  var cycle = Cycle()
  let active = Cycle.Window(id: 1, frame: topLeft)
  let touching = Cycle.Window(id: 2, frame: CGRect(x: 100, y: 20, width: 350, height: 250))
  let invalid = Cycle.Window(id: 3, frame: .infinite)
  #expect(cycle.select(.topLeft, in: display, windows: [active, touching, invalid], focusedWindowID: 1) == nil)
  #expect(cycle.select(.topLeft, in: display, windows: [active], focusedWindowID: nil) == nil)
  #expect(cycle.select(.topLeft, in: display, windows: [], focusedWindowID: 1) == nil)
}

@Test func quarterProbeUsesDisplayOriginAndSpacing() {
  let secondary = CGRect(x: -1100, y: 200, width: 1000, height: 800)
  #expect(WindowFocus.Quarter.allCases.map { $0.probe(in: secondary, spacing: 8) } == [
    CGRect(x: -1092, y: 208, width: 100, height: 140),
    CGRect(x: -208, y: 208, width: 100, height: 140),
    CGRect(x: -1092, y: 852, width: 100, height: 140),
    CGRect(x: -208, y: 852, width: 100, height: 140),
  ])
  #expect(WindowFocus.Quarter.topLeft.probe(in: secondary) == CGRect(x: -1100, y: 200, width: 100, height: 140))
  #expect(WindowFocus.Quarter.topLeft.probe(in: .infinite) == nil)
  #expect(WindowFocus.Quarter.topLeft.probe(in: secondary, spacing: .nan) == nil)
}
