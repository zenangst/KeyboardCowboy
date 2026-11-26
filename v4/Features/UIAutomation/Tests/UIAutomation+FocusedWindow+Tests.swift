import Testing
@testable import UIAutomationFeature

@Test func focusedElementWindowDoesNotUseApplicationFallback() throws {
  let window = try UIAutomation.resolveWindow(focus: { 1 }, ancestor: { $0 + 1 }, fallback: {
    Issue.record("Unexpected fallback")
    return 3
  })
  #expect(window == 2)
}

@Test func nilAncestorDoesNotUseApplicationFallback() throws {
  let window = try UIAutomation.resolveWindow(focus: { 1 }, ancestor: { _ in nil }, fallback: {
    Issue.record("Unexpected fallback")
    return 3
  })
  #expect(window == nil)
}

@Test func failedFocusUsesApplicationFallback() throws {
  enum Failure: Error { case focus }
  let window = try UIAutomation.resolveWindow(focus: { throw Failure.focus }, ancestor: { (_: Int) in
    Issue.record("Unexpected ancestor lookup")
    return nil
  }, fallback: { 3 })
  #expect(window == 3)
}

@Test func cancelledFocusDoesNotUseApplicationFallback() {
  #expect(throws: CancellationError.self) {
    try UIAutomation.resolveWindow(focus: { throw CancellationError() }, ancestor: { (_: Int) in nil }, fallback: {
      Issue.record("Unexpected fallback")
      return 3
    })
  }
}
