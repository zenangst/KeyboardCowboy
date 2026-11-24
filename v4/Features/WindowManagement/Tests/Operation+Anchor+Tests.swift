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
