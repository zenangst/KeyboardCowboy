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
func directFrameRolesResolveAnchor(_ role: String) throws {
  #expect(try Mouse.target(roleDescription: role, at: .center, selectedFrame: { nil }) {
    CGRect(x: 0, y: 0, width: 10, height: 10)
  } == CGPoint(x: 10, y: 10))
}

@Test(arguments: ["button", "Image", "text entry area", "HTML content"])
func otherRolesDoNotReadGenericFrame(_ role: String) throws {
  #expect(try Mouse.target(roleDescription: role, at: .center, selectedFrame: { nil }) {
    Issue.record("Unexpected generic frame read")
    return .zero
  } == nil)
}

@Test(arguments: ["table", "outline", "list", "collection"])
func selectedRowUsesItsFrameWithoutContainerFallback(_ role: String) throws {
  let frame = CGRect(x: -100, y: 20, width: 40, height: 20)
  let point = try Mouse.target(roleDescription: role, at: .center, selectedFrame: { frame }) {
    Issue.record("Unexpected container frame read")
    return .zero
  }
  #expect(point == CGPoint(x: -75, y: 35))
}

@Test(arguments: ["table", "outline", "list", "collection"])
func selectedRowResolutionPreservesMissingSelectionAndFrameFailure(_ role: String) {
  enum Failure: Error { case frameUnavailable }
  func containerFrame() -> CGRect {
    Issue.record("Unexpected container frame fallback")
    return .zero
  }

  #expect(throws: Mouse.TargetError.noSelectedChild) {
    try Mouse.target(roleDescription: role, at: .center, selectedFrame: { nil }, frame: containerFrame)
  }
  #expect(throws: Failure.frameUnavailable) {
    try Mouse.target(roleDescription: role, at: .center, selectedFrame: { throw Failure.frameUnavailable },
                     frame: containerFrame)
  }
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
