import CoreGraphics
import Testing
@testable import WindowManagementFeature

@Test(arguments: [
  (WindowManagement.Direction.topLeading, -1, -1), (.top, 0, -1), (.topTrailing, 1, -1),
  (.leading, -1, 0), (.trailing, 1, 0),
  (.bottomLeading, -1, 1), (.bottom, 0, 1), (.bottomTrailing, 1, 1),
])
func directionalMoveUsesAXAxes(direction: WindowManagement.Direction, x: Int, y: Int) throws {
  let original = CGRect(x: -400, y: -200, width: 100, height: 80)
  let operation = try Operation.Move(direction: direction, distance: 32, constraint: .unconstrained)
  #expect(operation.requestedFrame(for: original) == original.offsetBy(dx: CGFloat(x * 32), dy: CGFloat(y * 32)))
}

@Test func constrainedMoveClampsBothEdgesAgainstPaddedVisibleAreaWithoutResizing() throws {
  let display = WindowManagement.Display(
    bounds: CGRect(x: -1000, y: -200, width: 1000, height: 700),
    visibleBounds: CGRect(x: -950, y: -170, width: 920, height: 650),
  )
  let constraint = WindowManagement.MoveConstraint.visibleArea(displays: [display], padding: 20)
  let original = CGRect(x: -800, y: 0, width: 200, height: 150)
  let upperLeft = try Operation.Move(direction: .topLeading, distance: 900, constraint: constraint)
  let lowerRight = try Operation.Move(direction: .bottomTrailing, distance: 900, constraint: constraint)
  #expect(upperLeft.requestedFrame(for: original) == CGRect(x: -930, y: -150, width: 200, height: 150))
  #expect(lowerRight.requestedFrame(for: original) == CGRect(x: -250, y: 310, width: 200, height: 150))
  let tooTall = CGRect(x: -800, y: 0, width: 200, height: 800)
  #expect(lowerRight.requestedFrame(for: tooTall) == CGRect(x: -250, y: -150, width: 200, height: 800))
  #expect(lowerRight.requestedFrame(for: CGRect(x: 100, y: 0, width: 100, height: 100)) == nil)
}

@Test func moveRejectsInvalidInputsAndTreatsZeroDistanceAsANoOp() throws {
  #expect(throws: WindowManagement.MoveError.invalidDistance) {
    try Operation.Move(direction: .top, distance: .infinity, constraint: .unconstrained)
  }
  #expect(throws: WindowManagement.MoveError.invalidPadding) {
    try Operation.Move(direction: .top, distance: 10, constraint: .visibleArea(displays: [], padding: -1))
  }
  let zero = try Operation.Move(direction: .top, distance: 0, constraint: .visibleArea(displays: []))
  let original = CGRect(x: 20, y: 20, width: 300, height: 300)
  #expect(zero.requestedFrame(for: original) == original)
}
