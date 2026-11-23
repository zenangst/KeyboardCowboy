import AccessibilitySystem
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

@Test(arguments: [Mouse.TargetKind.group, .frame])
func directFrameRolesResolveAnchor(_ kind: Mouse.TargetKind) throws {
  #expect(try Mouse.target(kind: kind, at: .center, selectedFrame: { nil }) {
    CGRect(x: 0, y: 0, width: 10, height: 10)
  } == CGPoint(x: 10, y: 10))
}

@Test(arguments: [
  (AccessibilitySystem.Role.group, Mouse.TargetKind.group),
  (.image, .frame), (.textField, .frame), (.table, .selectedChild),
  (.outline, .selectedChild), (.list, .list), (.scrollArea, .scrollArea), (.webArea, .webArea),
])
func stableRolesDoNotReadLocalizedDescription(_ role: AccessibilitySystem.Role, _ kind: Mouse.TargetKind) {
  #expect(Mouse.targetKind(role: role) {
    Issue.record("Unexpected localized description read")
    return "collection"
  } == kind)
}

@Test(arguments: ["outline row", "text", "collection", "row", "HTML content"])
func unclassifiedRolesUseOnlySupportedLegacyDescriptions(_ description: String) {
  let expected: Mouse.TargetKind? = switch description {
  case "outline row", "text": .frame
  case "collection": .collection
  case "HTML content": .webArea
  default: nil
  }
  #expect(Mouse.targetKind(role: .init(rawValue: "AXUnclassified"), legacyDescription: { description }) == expected)
}

@Test(arguments: [Mouse.TargetKind.selectedChild, .list, .collection, .scrollArea, .webArea])
func selectedRowUsesItsFrameWithoutContainerFallback(_ kind: Mouse.TargetKind) throws {
  let frame = CGRect(x: -100, y: 20, width: 40, height: 20)
  let point = try Mouse.target(kind: kind, at: .center, selectedFrame: { frame }) {
    Issue.record("Unexpected container frame read")
    return .zero
  }
  #expect(point == CGPoint(x: -75, y: 35))
}

@Test(arguments: [Mouse.TargetKind.selectedChild, .list, .collection, .scrollArea, .webArea])
func selectedRowResolutionPreservesMissingSelectionAndFrameFailure(_ kind: Mouse.TargetKind) {
  enum Failure: Error { case frameUnavailable }
  func containerFrame() -> CGRect {
    Issue.record("Unexpected container frame fallback")
    return .zero
  }

  #expect(throws: Mouse.TargetError.noSelectedChild) {
    try Mouse.target(kind: kind, at: .center, selectedFrame: { nil }, frame: containerFrame)
  }
  #expect(throws: Failure.frameUnavailable) {
    try Mouse.target(kind: kind, at: .center, selectedFrame: { throw Failure.frameUnavailable },
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
