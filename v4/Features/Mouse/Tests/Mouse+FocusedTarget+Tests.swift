import CoreGraphics
@testable import MouseFeature
import Testing

@Test(arguments: [
  (Mouse.Anchor.topLeading, CGPoint(x: -95, y: 25)),
  (.top, CGPoint(x: -75, y: 25)),
  (.topTrailing, CGPoint(x: -55, y: 25)),
  (.leading, CGPoint(x: -95, y: 35)),
  (.center, CGPoint(x: -75, y: 35)),
  (.trailing, CGPoint(x: -55, y: 35)),
  (.bottomLeading, CGPoint(x: -95, y: 45)),
  (.bottom, CGPoint(x: -75, y: 45)),
  (.bottomTrailing, CGPoint(x: -55, y: 45)),
  (.custom(x: -7, y: -8), CGPoint(x: -2, y: -3)),
])
func mouseAnchorsUseGlobalCoordinatesAndLegacyOffset(_ anchor: Mouse.Anchor, _ expected: CGPoint) {
  #expect(anchor.point(in: CGRect(x: -100, y: 20, width: 40, height: 20)) == expected)
}

@Test(arguments: ["group", "image", "outline row", "text", "text field"])
func directFrameRolesResolveAnchor(_ role: String) {
  #expect(Mouse.target(roleDescription: role, at: .center) {
    CGRect(x: 0, y: 0, width: 10, height: 10)
  } == CGPoint(x: 10, y: 10))
}

@Test(arguments: ["button", "Image", "table", "text entry area", "HTML content"])
func otherRolesDoNotReadGenericFrame(_ role: String) {
  #expect(Mouse.target(roleDescription: role, at: .center) {
    Issue.record("Unexpected generic frame read")
    return .zero
  } == nil)
}

@Test func groupTargetToleratesMissingFocusAndShortCircuitsWhenFocused() {
  enum Failure: Error { case unavailable }
  #expect(Mouse.isGroupTarget(focused: { throw Failure.unavailable }, selected: { true }))
  #expect(Mouse.isGroupTarget(focused: { true }, selected: {
    Issue.record("Unexpected selection read")
    return false
  }))
  #expect(!Mouse.isGroupTarget(focused: { false }, selected: { throw Failure.unavailable }))
}
