import CoreGraphics
@testable import MouseFeature
import Testing

@Test(arguments: [
  (Mouse.Anchor.leading, CGPoint(x: -87, y: 30)),
  (.trailing, CGPoint(x: 309, y: 30)),
  (.top, CGPoint(x: -77, y: 25)),
  (.custom(x: -8, y: 10), CGPoint(x: -3, y: 15)),
])
func xcodeNoncenterAnchorsUseLegacyEditorIncrements(_ anchor: Mouse.Anchor, _ expected: CGPoint) {
  let bounds = CGRect(x: 40, y: 20, width: 20, height: 10)
  let frame = Mouse.textTargetFrame(bounds, at: anchor, applicationBundleIdentifier: "com.apple.dt.Xcode") {
    CGRect(x: -100, y: 0, width: 400, height: 200)
  }
  #expect(anchor.point(in: frame) == expected)
}

@Test func xcodeCenterAndOtherAppsDoNotReadControlFrame() {
  let bounds = CGRect(x: 40, y: 20, width: 20, height: 10)
  func unexpectedFrame() -> CGRect {
    Issue.record("Unexpected control frame read")
    return .zero
  }

  #expect(Mouse.textTargetFrame(bounds, at: .center, applicationBundleIdentifier: "com.apple.dt.Xcode",
                                controlFrame: unexpectedFrame) == bounds)
  #expect(Mouse.textTargetFrame(bounds, at: .leading, applicationBundleIdentifier: "com.apple.TextEdit",
                                controlFrame: unexpectedFrame) == bounds)
}

@Test func xcodeNoncenterAnchorPropagatesControlFrameFailure() {
  enum Failure: Error { case missingFrame }
  #expect(throws: Failure.missingFrame) {
    try Mouse.textTargetFrame(.zero, at: .leading, applicationBundleIdentifier: "com.apple.dt.Xcode") {
      throw Failure.missingFrame
    }
  }
}
