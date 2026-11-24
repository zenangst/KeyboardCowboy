import CoreGraphics
import Testing
@testable import WindowTilingFeature

@Test func dynamicQuartersUsesClassifiedSideAndDoesNotGuessUnknownLayouts() {
  for layout in [WindowTiling.Action.left, .topLeft, .bottomLeft, .fill] {
    #expect(WindowTiling.dynamicAction(count: 2, layout: layout) == .arrangeLeftRight)
    #expect(WindowTiling.dynamicAction(count: 3, layout: layout) == .arrangeLeftQuarters)
  }
  for layout in [WindowTiling.Action.right, .topRight, .bottomRight, .center, .top, .bottom] {
    #expect(WindowTiling.dynamicAction(count: 2, layout: layout) == .arrangeRightLeft)
    #expect(WindowTiling.dynamicAction(count: 4, layout: layout) == .arrangeRightQuarters)
  }
  #expect(WindowTiling.dynamicAction(count: 0, layout: .left) == nil)
  #expect(WindowTiling.dynamicAction(count: 1, layout: nil) == .fill)
  #expect(WindowTiling.dynamicAction(count: 3, layout: nil) == nil)
}

@Test func classifiesHalvesQuartersFillAndCenterOnAnOffsetDisplay() {
  let screen = CGRect(x: 2560, y: 285, width: 1539, height: 1155)
  let layouts: [(WindowTiling.Action, CGRect)] = [
    (.fill, CGRect(x: 2568, y: 293, width: 1523, height: 1139)),
    (.left, CGRect(x: 2568, y: 293, width: 757, height: 1139)),
    (.right, CGRect(x: 3333, y: 293, width: 758, height: 1139)),
    (.top, CGRect(x: 2568, y: 293, width: 1523, height: 565)),
    (.bottom, CGRect(x: 2568, y: 866, width: 1523, height: 566)),
    (.topLeft, CGRect(x: 2568, y: 293, width: 757, height: 565)),
    (.topRight, CGRect(x: 3333, y: 293, width: 758, height: 565)),
    (.bottomLeft, CGRect(x: 2568, y: 866, width: 757, height: 566)),
    (.bottomRight, CGRect(x: 3333, y: 866, width: 758, height: 566)),
    (.center, CGRect(x: 3029, y: 662, width: 601, height: 401)),
  ]
  for (action, frame) in layouts {
    #expect(WindowTiling.classify(frame, in: screen, margin: 8) == action)
    #expect(WindowTiling.classify(frame.offsetBy(dx: -4099, dy: -1440),
                                  in: screen.offsetBy(dx: -4099, dy: -1440), margin: 8) == action)
  }
  // A standalone native tile can round differently than a four-up arrangement.
  #expect(WindowTiling.classify(CGRect(x: 2568, y: 293, width: 758, height: 566), in: screen, margin: 8) == .topLeft)
}

@Test func classificationUsesEdgeToleranceAndDoesNotGuessFill() {
  let screen = CGRect(x: 0, y: 24, width: 1200, height: 800)
  let left = CGRect(x: 0.5, y: 24, width: 600, height: 800)
  #expect(WindowTiling.classify(left, in: screen, margin: 0) == .left)
  #expect(WindowTiling.classify(left, in: screen, margin: 0, tolerance: 0) == nil)
  #expect(WindowTiling.classify(screen.offsetBy(dx: 40, dy: 0), in: screen, margin: 0) == nil)
  #expect(WindowTiling.classify(CGRect(x: 400, y: 100, width: 400, height: 300), in: screen, margin: 0) == nil)
  #expect(WindowTiling.classify(.zero, in: screen, margin: 0) == nil)
  #expect(WindowTiling.classify(screen, in: screen, margin: 400) == nil)
  #expect(WindowTiling.classify(screen, in: screen, margin: -.infinity) == nil)
  #expect(WindowTiling.classify(screen, in: screen, margin: 0, tolerance: .nan) == nil)
}
