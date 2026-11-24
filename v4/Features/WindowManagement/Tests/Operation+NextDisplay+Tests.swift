import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let primary = WindowManagement.Display(
  bounds: CGRect(x: 0, y: 0, width: 1200, height: 800),
  visibleBounds: CGRect(x: 0, y: 24, width: 1150, height: 776),
)
private let secondary = WindowManagement.Display(
  bounds: CGRect(x: -800, y: -150, width: 800, height: 600),
  visibleBounds: CGRect(x: -780, y: -120, width: 780, height: 570),
)

@Test func nextDisplayCentersInUsableBoundsAndWrapsWithoutResizing() {
  let operation = Operation.NextDisplay(displays: [primary, secondary])
  let original = CGRect(x: 100, y: 130, width: 400, height: 200)
  let moved = CGRect(x: -590, y: 65, width: 400, height: 200)
  #expect(operation.requestedFrame(for: original) == moved)
  #expect(operation.requestedFrame(for: moved) == CGRect(x: 375, y: 312, width: 400, height: 200))
}

@Test func nextDisplayUsesGreatestOverlapAndSkipsUnusableAndMirroredBounds() {
  let invalid = WindowManagement.Display(bounds: .zero, visibleBounds: .zero)
  let operation = Operation.NextDisplay(displays: [primary, primary, invalid, secondary])
  // The origin is on the secondary, but most of the frame is on the primary.
  let original = CGRect(x: -50, y: 100, width: 400, height: 650)
  #expect(operation.requestedFrame(for: original) == CGRect(x: -590, y: -120, width: 400, height: 650))
}

@Test func nextDisplayHasNoTargetWithoutAnAlternateOrAnIntersectingDisplay() {
  let original = CGRect(x: 100, y: 130, width: 400, height: 200)
  #expect(Operation.NextDisplay(displays: [primary]).requestedFrame(for: original) == nil)
  #expect(Operation.NextDisplay(displays: [primary, primary]).requestedFrame(for: original) == nil)
  let offscreen = original.offsetBy(dx: 2000, dy: 1000)
  #expect(Operation.NextDisplay(displays: [primary, secondary]).requestedFrame(for: offscreen) == nil)
}
