import AccessibilitySystem
import AppKit
import ApplicationServices
import Carbon
import Foundation
@testable import HostInput
import MachPortSystem
import Testing
import TextFeature

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_TEXTEDIT_TYPING_SMOKE"] == "1"))
func liveTextEditTyping() async throws {
  enum SmokeFailure: Error { case focusChanged, inputSourceChanged }

  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before starting.")
  try #require(CGPreflightPostEventAccess(), "Grant event posting access before starting.")
  let app = try #require(NSWorkspace.shared.frontmostApplication)
  try #require(app.bundleIdentifier == "com.apple.TextEdit", "Focus a blank, disposable TextEdit document.")
  let pid = app.processIdentifier
  let layouts = HostInput.KeyboardLayoutSession()
  let cases = [
    (name: "US", quoteKey: "'", sample: "US: åæøäö ÅÆØÄÖ\n"),
    (name: "Norwegian", quoteKey: "æ", sample: "Norwegian: åæø ÅÆØ\n"),
    (name: "Swedish-Pro", quoteKey: "ä", sample: "Swedish: åäö ÅÄÖ"),
  ]

  let client = AccessibilitySystem.Client()
  let id = try await client.withApplication(processIdentifier: pid) { session in
    let window = try #require(try session.focusedWindow())
    let id = try #require(try session.windowIDCandidate(for: window))
    let editor = try session.focusedElement()
    try #require(try session.read(.role, of: editor) == .textArea, "Place the caret in the document body.")
    let blank = try session.read(.textValue, of: editor).isEmpty
    try #require(blank, "The document must be empty.")
    return id
  }
  guard NSWorkspace.shared.frontmostApplication?.isEqual(app) == true else { throw SmokeFailure.focusChanged }

  let source = try #require(CGEventSource(stateID: .privateState))
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: source, syntheticSignature: 0x4B43_5634)
  let post = HostInput.textPosting { code, action, flags in
    guard NSWorkspace.shared.frontmostApplication?.isEqual(app) == true else { throw SmokeFailure.focusChanged }

    try poster.post(keyCode: code, action: action, flags: flags)
  }
  let typing = HostInput.textTyping(layouts: layouts, post: post) { text in
    guard NSWorkspace.shared.frontmostApplication?.isEqual(app) == true else { throw SmokeFailure.focusChanged }

    try poster.postUnicode(text)
  }
  let executor = TextExecutor(typing: typing, instant: { _ in
    Issue.record("The smoke test must use Typing mode.")
  })
  func documentMatches(_ expected: String) async throws -> Bool {
    try await client.withApplication(processIdentifier: pid) { session in
      guard NSWorkspace.shared.frontmostApplication?.isEqual(app) == true,
            let window = try session.focusedWindow(), try session.windowIDCandidate(for: window) == id
      else { throw SmokeFailure.focusChanged }

      let editor = try session.focusedElement()
      guard try session.read(.role, of: editor) == .textArea else { throw SmokeFailure.focusChanged }

      return try session.read(.textValue, of: editor) == expected
        && session.read(.selectedTextRange, of: editor) == NSRange(location: expected.utf16.count, length: 0)
    }
  }

  let sources = try SmokeInputSources()
  defer { sources.restore() }
  let clock = ContinuousClock()
  var expected = ""
  for entry in cases {
    try #require(try await documentMatches(expected), "Keep the caret at the end of the disposable document.")
    let sourceID = "com.apple.keylayout.\(entry.name)"
    try sources.select(sourceID)
    let layoutDeadline = clock.now + .seconds(5)
    while clock.now < layoutDeadline,
          currentSourceID() != sourceID || layouts.layout?.displayValue(for: kVK_ANSI_Quote) != entry.quoteKey {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(currentSourceID() == sourceID && layouts.layout?.displayValue(for: kVK_ANSI_Quote) == entry.quoteKey,
                 "The cached \(entry.name) layout did not become active.")
    try #require(try await documentMatches(expected))
    guard currentSourceID() == sourceID else { throw SmokeFailure.inputSourceChanged }

    try await executor.run(.init(input: entry.sample, mode: .typing))
    expected += entry.sample

    let deadline = clock.now + .seconds(2)
    var matchingSince: ContinuousClock.Instant?
    var settled = false
    while clock.now < deadline {
      guard currentSourceID() == sourceID else { throw SmokeFailure.inputSourceChanged }
      if try await documentMatches(expected) {
        let now = clock.now
        let start = matchingSince ?? now
        matchingSince = start
        if now - start >= .milliseconds(500) {
          settled = true
          break
        }
      } else {
        matchingSince = nil
      }
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(settled, "TextEdit did not retain the exact cumulative sample after \(entry.name).")
  }
}
