import CoreGraphics
import Testing
@testable import UIElementFeature

@Test func pointerClickRequiresMouseBasedRoleAndKnownPosition() {
  #expect(UIElement.usesPointerClick(role: .staticText, pointer: .zero))
  #expect(UIElement.usesPointerClick(role: .cell, pointer: .zero))
  #expect(!UIElement.usesPointerClick(role: .cell, pointer: nil))
  #expect(!UIElement.usesPointerClick(role: .button, pointer: .zero))
}

@MainActor
@Test func clickRestoresOriginalPointerAfterWait() async throws {
  let point = CGPoint(x: -100, y: 80)
  let original = CGPoint(x: 40, y: 60)
  var events: [String] = []
  try await UIElement.clickAndRestore(at: point, original: original, click: {
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
    try await UIElement.clickAndRestore(at: .zero, original: original, click: { _ in },
                                        restore: { restored.append($0) },
                                        wait: { throw CancellationError() })
  }
  #expect(restored == [original])
}
