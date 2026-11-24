import CoreGraphics
import Testing
@testable import WindowManagementFeature

private let display = WindowManagement.Display(
  bounds: CGRect(x: -900, y: -200, width: 900, height: 700),
  visibleBounds: CGRect(x: -880, y: -175, width: 860, height: 655),
)
private let original = CGRect(x: -800, y: -50, width: 400, height: 250)
private let requested = CGRect(x: -864, y: -159, width: 828, height: 623)

@Test func fillUsesSymmetricPaddingOnNegativeOriginDisplay() throws {
  let operation = try Operation.Fill(displays: [display], padding: 16)
  #expect(operation.requestedFrame(for: original) == requested)
}

@Test(arguments: [-1, CGFloat.infinity, .nan])
func fillRejectsInvalidPadding(padding: CGFloat) {
  #expect(throws: WindowManagement.FillError.invalidPadding) {
    try Operation.Fill(displays: [display], padding: padding)
  }
}

@Test func fillCannotRequestAFrameWhenPaddingLeavesNoArea() throws {
  let noRoom = try Operation.Fill(displays: [display], padding: 400)
  #expect(noRoom.requestedFrame(for: original) == nil)
}
