import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let original = CGRect(x: -400, y: 100, width: 200, height: 100)

@Test(arguments: [
  (WindowManagement.Direction.topLeading, -1, -1), (.top, 0, -1), (.topTrailing, 1, -1),
  (.leading, -1, 0), (.trailing, 1, 0),
  (.bottomLeading, -1, 1), (.bottom, 0, 1), (.bottomTrailing, 1, 1),
])
func growMovesOnlySelectedEdgesAndShrinkReversesIt(direction: WindowManagement.Direction, x: Int, y: Int) throws {
  let grow = try Operation.Resize(change: .grow, direction: direction, distance: 25, constraint: .unconstrained)
  let shrink = try Operation.Resize(change: .shrink, direction: direction, distance: 25, constraint: .unconstrained)
  let expected = CGRect(x: original.minX + CGFloat(min(0, x) * 25), y: original.minY + CGFloat(min(0, y) * 25),
                        width: original.width + CGFloat(abs(x) * 25), height: original.height + CGFloat(abs(y) * 25))
  #expect(grow.requestedFrame(for: original) == expected)
  #expect(shrink.requestedFrame(for: expected) == original)
}

@Test func constrainedGrowthStopsAtPaddedBoundsWithoutMovingOppositeEdges() throws {
  let display = WindowManagement.Display(
    bounds: CGRect(x: -800, y: -200, width: 800, height: 800),
    visibleBounds: CGRect(x: -750, y: -170, width: 750, height: 750),
  )
  let operation = try Operation.Resize(change: .grow, direction: .topLeading, distance: 600,
                                       constraint: .visibleArea(displays: [display], padding: 20))
  #expect(operation.requestedFrame(for: original) == CGRect(x: -730, y: -150, width: 530, height: 350))
  #expect(operation.requestedFrame(for: original.offsetBy(dx: 250, dy: 0)) == nil)
}

@Test func shrinkNeverRequestsZeroOrNegativeSize() throws {
  let operation = try Operation.Resize(change: .shrink, direction: .topLeading, distance: 500, constraint: .unconstrained)
  #expect(operation.requestedFrame(for: original) == CGRect(x: -201, y: 199, width: 1, height: 1))
}

@Test func resizeRejectsInvalidInputsAndZeroDistancePreservesTheFrame() throws {
  #expect(throws: WindowManagement.ResizeError.invalidDistance) {
    try Operation.Resize(change: .shrink, direction: .bottom, distance: .nan, constraint: .unconstrained)
  }
  #expect(throws: WindowManagement.ResizeError.invalidPadding) {
    try Operation.Resize(change: .grow, direction: .trailing, distance: 10, constraint: .visibleArea(displays: [], padding: -1))
  }
  let operation = try Operation.Resize(change: .grow, direction: .top, distance: 0, constraint: .unconstrained)
  #expect(operation.requestedFrame(for: original) == original)
}
