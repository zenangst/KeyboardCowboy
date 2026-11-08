import Carbon
import Testing
import TextFeature

@Test @MainActor func instantFallbackPreservesEffectOrder() async throws {
  var log: [String] = []
  let instant = TextInstant(
    insertDirectly: { log.append("direct:\($0)"); return false },
    clearPasteboard: { log.append("clear") },
    writePasteboard: { log.append("write:\($0)") },
    post: { log.append("post:\($0):\($1):\($2.rawValue)") },
    observeText: { log.append("text:\($0)") },
    observeReturn: { log.append("return") },
    sleep: { log.append("sleep:\($0)") },
  )
  try await instant.run(TextExecution(input: "hello", actions: [.insertEnter]))
  #expect(log == ["direct:hello", "clear", "write:hello", "text:hello", "sleep:0.1 seconds",
                  "post:\(kVK_ANSI_V):down:4", "post:\(kVK_ANSI_V):up:4", "return", "sleep:0.05 seconds",
                  "post:\(kVK_Return):down:0", "post:\(kVK_Return):up:0"])
}

@Test @MainActor func instantDirectInsertionSkipsPasteAndCanAddReturn() async throws {
  var log: [String] = []
  let instant = TextInstant(
    insertDirectly: { log.append("direct:\($0)"); return true },
    clearPasteboard: { log.append("clear") },
    writePasteboard: { _ in log.append("write") },
    post: { code, event, _ in log.append("post:\(code):\(event)") },
    observeText: { _ in log.append("text") },
    observeReturn: { log.append("return") },
    sleep: { log.append("sleep:\($0)") },
  )
  try await instant.run(TextExecution(input: "hello", actions: [.insertEnter]))
  #expect(log == ["direct:hello", "return", "sleep:0.05 seconds", "post:\(kVK_Return):down", "post:\(kVK_Return):up"])
}

@Test @MainActor func instantCancellationStopsBeforePaste() async {
  var log: [String] = []
  let instant = TextInstant(
    insertDirectly: { _ in false },
    clearPasteboard: { log.append("clear") },
    writePasteboard: { _ in log.append("write") },
    post: { _, _, _ in log.append("post") },
    observeReturn: { log.append("return") },
    sleep: { _ in throw CancellationError() },
  )
  await #expect(throws: CancellationError.self) {
    try await instant.run(TextExecution(input: "hello", actions: [.insertEnter]))
  }
  #expect(log == ["clear", "write"])
}

@Test @MainActor func instantEmptyInputDoesNothing() async throws {
  var called = false
  let instant = TextInstant(
    insertDirectly: { _ in called = true; return false },
    clearPasteboard: { called = true },
    writePasteboard: { _ in called = true },
    post: { _, _, _ in called = true },
    observeReturn: { called = true },
  )
  try await instant.run(TextExecution(input: "", actions: [.insertEnter]))
  #expect(!called)
}
