import Carbon
import Foundation
@testable import HostInput
import KeyCodeSystem
import Testing
import TextFeature

@MainActor
@Test func hostTypingAvoidsOptionBindingsForNordicLettersOnUSLayout() async throws {
  let layout = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let layouts = HostInput.KeyboardLayoutSession(center: NotificationCenter()) { layout }
  var trace: [String] = []
  let typing = HostInput.textTyping(layouts: layouts, post: { code, event, modifiers in
    trace.append("\(code):\(event == .down ? "down" : "up"):\(modifiers.rawValue)")
  }, postUnmapped: {
    trace.append($0)
  })
  try await typing(.init(input: "AåæøäöÅÆØÄÖ", mode: .typing))

  let shift = TextTyping.Modifiers.shift.rawValue
  let expected = ["\(kVK_ANSI_A):down:\(shift)", "\(kVK_ANSI_A):up:\(shift)"] + "åæøäöÅÆØÄÖ".map(String.init)
  #expect(trace == expected)
}

@MainActor
@Test(arguments: [
  ("Norwegian", "åæø ÅÆØ"),
  ("Swedish", "åäö ÅÄÖ"),
  ("Swedish-Pro", "åäö ÅÄÖ"),
])
func hostTypingResolvesNordicLettersWithoutDeadKeySequences(layoutName: String, sample: String) async throws {
  let layout = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.\(layoutName)")
  let layouts = HostInput.KeyboardLayoutSession(center: NotificationCenter()) { layout }
  var events: [(Int, TextTyping.KeyEvent, TextTyping.Modifiers)] = []
  let typing = HostInput.textTyping(layouts: layouts) { code, action, modifiers in
    events.append((code, action, modifiers))
  }
  try await typing(.init(input: sample, mode: .typing))

  let letters = [kVK_ANSI_LeftBracket, kVK_ANSI_Quote, kVK_ANSI_Semicolon]
  let codes = letters + [kVK_Space] + letters
  #expect(events.map(\.0) == codes.flatMap { [$0, $0] })
  #expect(events.map(\.1) == codes.flatMap { _ in [TextTyping.KeyEvent.down, .up] })
  #expect(events.map(\.2) == Array(repeating: [], count: 8) + Array(repeating: .shift, count: 6))
}

@MainActor
@Test func hostTypingUsesOneLayoutPerCommandAndPicksUpRefreshOnTheNextCommand() async throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  let center = NotificationCenter()
  var next = us
  var loads = 0
  let layouts = HostInput.KeyboardLayoutSession(center: center) {
    loads += 1
    return next
  }
  var events: [(Int, TextTyping.KeyEvent, TextTyping.Modifiers)] = []
  let typing = HostInput.textTyping(layouts: layouts) { code, action, modifiers in
    events.append((code, action, modifiers))
    if events.count == 1 {
      next = french
      center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
    }
  }
  try await typing(.init(input: "aa", mode: .typing))
  try await typing(.init(input: "Aé ", mode: .typing))

  let codes = [kVK_ANSI_A, kVK_ANSI_A, kVK_ANSI_Q, kVK_ANSI_2, kVK_Space]
  #expect(events.map(\.0) == codes.flatMap { [$0, $0] })
  #expect(events.map(\.1) == codes.flatMap { _ in [TextTyping.KeyEvent.down, .up] })
  #expect(events.map(\.2) == [[], [], [], [], .shift, .shift, [], [], [], []])
  #expect(loads == 2)
}

@MainActor
@Test func hostTypingDoesNotPostWithoutALayout() async throws {
  let layouts = HostInput.KeyboardLayoutSession(center: NotificationCenter()) {
    throw KeyCodeSystem.LookupError.layoutUnavailable
  }
  let typing = HostInput.textTyping(layouts: layouts) { _, _, _ in
    Issue.record("Unexpected post")
  }
  try await typing(.init(input: "", mode: .typing))
  await #expect(throws: KeyCodeSystem.LookupError.layoutUnavailable) {
    try await typing(.init(input: "a", mode: .typing, actions: [.insertEnter]))
  }
  try await HostInput.textTyping(using: nil, layouts: layouts)(.init(input: "a", mode: .typing))
}
