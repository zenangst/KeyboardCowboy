import AccessibilitySystem
import AppKit
import ApplicationServices
import Foundation
import HostInput
import KeyboardFeature
import MachPortSystem
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SHORTCUT_POSTING_SMOKE"] == "1"))
func liveShortcutPosting() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before starting.")
  try #require(CGPreflightPostEventAccess(), "Grant event posting access before starting.")
  let app = try #require(NSWorkspace.shared.frontmostApplication)
  try #require(app.bundleIdentifier == "com.apple.TextEdit", "Focus a blank, disposable TextEdit document.")
  let pid = app.processIdentifier
  let client = AccessibilitySystem.Client()
  let windowID = try await client.withApplication(processIdentifier: pid) { session in
    let window = try #require(try session.focusedWindow())
    return try #require(try session.windowIDCandidate(for: window))
  }
  func matches(_ expected: String) async throws -> Bool {
    try await client.withApplication(processIdentifier: pid) { session in
      guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
            let window = try session.focusedWindow(),
            try session.windowIDCandidate(for: window) == windowID else { return false }

      let editor = try session.focusedElement()
      return try session.read(.role, of: editor) == .textArea
        && session.read(.textValue, of: editor) == expected
        && session.read(.selectedTextRange, of: editor) == NSRange(location: expected.utf16.count, length: 0)
    }
  }

  let layouts = HostInput.KeyboardLayoutSession()
  try #require(layouts.layout?.keyCode(for: "a") != nil, "Use a layout with an unmodified A key.")
  let source = try #require(CGEventSource(stateID: .privateState))
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: source, syntheticSignature: 0x4B43_5634)
  try #require(try await matches(""), "The focused TextEdit document must be blank, with the caret in its body.")
  try #require(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid)
  try HostInput.executeShortcuts([Keyboard.Shortcut(key: "a", modifiers: [.leftShift])], using: poster, layouts: layouts)

  let deadline = ContinuousClock.now + .seconds(3)
  while ContinuousClock.now < deadline {
    if try await matches("A") { return }
    try await Task.sleep(for: .milliseconds(50))
  }
  Issue.record("The same TextEdit document did not receive the expected shortcut output.")
}
