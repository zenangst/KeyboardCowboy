import Testing
import TextFeature
import Carbon

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

@Test(arguments: 0..<5) @MainActor func typingStopsAtFirstMatchingLookup(matchIndex: Int) async throws {
  let attempts: [(TextTyping.Modifiers, Bool)] = [
    ([], true), (.shift, true), (.option, true), ([.option, .shift], true), ([], false),
  ]
  var lookups: [(TextTyping.Modifiers, Bool)] = []
  var posts: [(Int, TextTyping.KeyEvent, TextTyping.Modifiers)] = []
  let typing = TextTyping(lookup: { _, modifiers, display in
    lookups.append((modifiers, display))
    return lookups.count - 1 == matchIndex ? 42 : nil
  }, post: { posts.append(($0, $1, $2)) })
  try await typing.run(TextExecution(input: "a", mode: .typing))
  #expect(lookups.count == matchIndex + 1)
  for (index, lookup) in lookups.enumerated() {
    #expect(lookup.0 == attempts[index].0)
    #expect(lookup.1 == attempts[index].1)
  }
  #expect(posts.count == 2)
  #expect(posts[0].0 == 42 && posts[0].1 == .down && posts[0].2 == attempts[matchIndex].0)
  #expect(posts[1].0 == 42 && posts[1].1 == .up && posts[1].2 == attempts[matchIndex].0)
}

@Test @MainActor func typingHandlesNewlinesAndCombinedCharacters() async throws {
  var observed: [String] = []
  var lookedUp: [String] = []
  var codes: [Int] = []
  let typing = TextTyping(lookup: { text, _, _ in
    lookedUp.append(text)
    return 7
  }, post: { code, _, _ in codes.append(code) }, observeText: { observed.append($0) })
  try await typing.run(TextExecution(input: "\n\r\r\ne\u{301}", mode: .typing))
  #expect(observed == ["\n", "\r", "\r\n", "e\u{301}"])
  #expect(lookedUp == ["e\u{301}"])
  #expect(codes == [kVK_Return, kVK_Return, kVK_Return, kVK_Return, kVK_Return, kVK_Return, 7, 7])
}

@Test @MainActor func typingKeyUpFailureStopsBeforeNextCharacter() async {
  enum Failure: Error { case post }
  var log: [String] = []
  let typing = TextTyping(lookup: { _, _, _ in 1 }, post: { _, event, _ in
    log.append("\(event)")
    if event == .up { throw Failure.post }
  }, observeText: { log.append($0) }, observeReturn: { log.append("return") })
  await #expect(throws: Failure.post) {
    try await typing.run(TextExecution(input: "ab", mode: .typing, actions: [.insertEnter]))
  }
  #expect(log == ["a", "down", "up"])
}
