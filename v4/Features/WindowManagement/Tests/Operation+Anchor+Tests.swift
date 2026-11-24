import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let display = WindowManagement.Display(
  bounds: CGRect(x: -1000, y: -200, width: 1000, height: 700),
  visibleBounds: CGRect(x: -940, y: -170, width: 940, height: 640),
)
private let original = CGRect(x: -800, y: -100, width: 440, height: 390)

@Test(arguments: [
  (WindowManagement.Direction.topLeading, -920, -150, 450, 300),
  (.top, -920, -150, 900, 400),
  (.topTrailing, -470, -150, 450, 300),
  (.leading, -920, -150, 450, 600),
  (.trailing, -470, -150, 450, 600),
  (.bottomLeading, -920, 150, 450, 300),
  (.bottom, -920, 50, 900, 400),
  (.bottomTrailing, -470, 150, 450, 300),
])
func anchorUsesPaddedVisibleAreaForAllDirections(
  direction: WindowManagement.Direction, x: Int, y: Int, width: Int, height: Int,
) throws {
  let anchor = try Operation.Anchor(direction: direction, displays: [display], padding: 20)
  #expect(anchor.requestedFrame(for: original) == CGRect(x: x, y: y, width: width, height: height))
}

@Test func anchorChoosesSmallerBandOnATieAndRejectsUnusableTargets() throws {
  let anchor = try Operation.Anchor(direction: .leading, displays: [display], padding: 20)
  #expect(anchor.requestedFrame(for: CGRect(x: -800, y: -100, width: 375, height: 390))?.width == 300)
  #expect(anchor.requestedFrame(for: original.offsetBy(dx: 1200, dy: 0)) == nil)
  let noRoom = try Operation.Anchor(direction: .bottomTrailing, displays: [display], padding: 320)
  #expect(noRoom.requestedFrame(for: original) == nil)
  #expect(throws: WindowManagement.AnchorError.invalidPadding) {
    try Operation.Anchor(direction: .top, displays: [display], padding: .infinity)
  }
}

@Test func anchorRoundsInwardWithFractionalPadding() throws {
  let anchor = try Operation.Anchor(direction: .bottomTrailing, displays: [display], padding: 20.25)
  let result = try #require(anchor.requestedFrame(for: original))
  #expect(result.maxX == -21)
  #expect(result.maxY == 449)
  #expect(display.visibleBounds.insetBy(dx: 20.25, dy: 20.25).contains(result))
}

@Test func anchorCyclesOnlyFromAMatchingFrameAndWraps() throws {
  let anchor = try Operation.Anchor(direction: .bottomTrailing, displays: [display], padding: 20, mode: .cycle)
  let small = CGRect(x: -320, y: 250, width: 300, height: 200)
  let middle = CGRect(x: -470, y: 150, width: 450, height: 300)
  let large = CGRect(x: -620, y: 50, width: 600, height: 400)
  #expect(anchor.requestedFrame(for: small) == middle)
  #expect(anchor.requestedFrame(for: middle) == large)
  #expect(anchor.requestedFrame(for: large) == small)
  #expect(anchor.requestedFrame(for: middle.offsetBy(dx: -2, dy: 0)) == middle)
  #expect(anchor.requestedFrame(for: middle.insetBy(dx: 0, dy: 5)) == middle)
}

@Test func cardinalCycleUsesItsAnchoredAxisAndSkipsIdenticalBands() throws {
  let top = try Operation.Anchor(direction: .top, displays: [display], padding: 20, mode: .cycle)
  let small = CGRect(x: -920, y: -150, width: 900, height: 200)
  #expect(top.requestedFrame(for: small) == CGRect(x: -920, y: -150, width: 900, height: 300))
  let tiny = CGRect(x: 0, y: 0, width: 4, height: 3)
  let leading = try Operation.Anchor(direction: .leading, displays: [.init(bounds: tiny, visibleBounds: tiny)], padding: 0, mode: .cycle)
  #expect(leading.requestedFrame(for: CGRect(x: 0, y: 0, width: 2, height: 3)) == CGRect(x: 0, y: 0, width: 3, height: 3))
}
