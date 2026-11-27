import CoreGraphics
import Testing
@testable import UIAutomationFeature

@Test func pointerClickRequiresMouseBasedRoleAndKnownPosition() {
  #expect(UIAutomation.usesPointerClick(role: .staticText, pointer: .zero))
  #expect(UIAutomation.usesPointerClick(role: .cell, pointer: .zero))
  #expect(!UIAutomation.usesPointerClick(role: .cell, pointer: nil))
  #expect(!UIAutomation.usesPointerClick(role: .button, pointer: .zero))
}

@MainActor
@Test func clickRestoresOriginalPointerAfterWait() async throws {
  let point = CGPoint(x: -100, y: 80)
  let original = CGPoint(x: 40, y: 60)
  var events: [String] = []
  try await UIAutomation.clickAndRestore(at: point, original: original, click: {
    #expect($0 == point)
    events.append("click")
  }, restore: {
    #expect($0 == original)
    events.append("restore")
  }, wait: { events.append("wait") })
  #expect(events == ["click", "wait", "restore"])
}

@MainActor
@Test func clickRestoresOriginalPointerWhenWaitIsCancelled() async {
  let original = CGPoint(x: 40, y: 60)
  var restored: [CGPoint] = []
  await #expect(throws: CancellationError.self) {
    try await UIAutomation.clickAndRestore(at: .zero, original: original, click: { _ in },
                                           restore: { restored.append($0) },
                                           wait: { throw CancellationError() })
  }
  #expect(restored == [original])
}
