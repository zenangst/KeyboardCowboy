import Testing
import TextFeature

@Test @MainActor func typingResolvesInOrderAndPostsGraphemes() async throws {
  var log: [String] = []
  let typing = TextTyping(
    lookup: { text, flags, display in
      log.append("lookup:\(text):\(flags.rawValue):\(display)")
      if text == "é" && flags == [.option, .shift] && display { return 12 }
      if text == "x" && !display { return 7 }
      return nil
    },
    post: { code, event, flags in log.append("post:\(code):\(event):\(flags.rawValue)") },
    observeText: { log.append("text:\($0)") },
    observeReturn: { log.append("return") },
    sleep: { log.append("sleep:\($0)") }
  )
  try await typing.run(TextExecution(input: "éx\r\n🙂", mode: .typing, actions: [.insertEnter]))
  #expect(log == [
    "text:é", "lookup:é:0:true", "lookup:é:1:true", "lookup:é:2:true", "lookup:é:3:true",
    "post:12:down:3", "post:12:up:3",
    "text:x", "lookup:x:0:true", "lookup:x:1:true", "lookup:x:2:true", "lookup:x:3:true", "lookup:x:0:false",
    "post:7:down:0", "post:7:up:0", "text:\r\n", "post:36:down:0", "post:36:up:0",
    "text:🙂", "lookup:🙂:0:true", "lookup:🙂:1:true", "lookup:🙂:2:true", "lookup:🙂:3:true", "lookup:🙂:0:false",
    "return", "sleep:0.05 seconds", "post:36:down:0", "post:36:up:0",
  ])
}

@Test @MainActor func typingStopsOnPostFailure() async {
  enum Failure: Error { case post }
  var log: [String] = []
  let typing = TextTyping(lookup: { _, _, _ in 1 }, post: { _, _, _ in
    log.append("post")
    throw Failure.post
  }, observeText: { log.append($0) }, observeReturn: { log.append("return") })
  await #expect(throws: Failure.post) {
    try await typing.run(TextExecution(input: "ab", mode: .typing, actions: [.insertEnter]))
  }
  #expect(log == ["a", "post"])
}

@Test @MainActor func typingEmptyInputIsNoOp() async throws {
  var called = false
  let typing = TextTyping(lookup: { _, _, _ in called = true; return nil }, post: { _, _, _ in called = true }, observeReturn: { called = true })
  try await typing.run(TextExecution(input: "", mode: .typing, actions: [.insertEnter]))
  #expect(!called)
}
