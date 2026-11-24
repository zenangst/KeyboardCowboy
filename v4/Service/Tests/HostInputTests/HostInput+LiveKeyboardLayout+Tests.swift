import Carbon
import Foundation
import HostInput
import KeyCodeSystem
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_LAYOUT_SMOKE"] == "1"))
func liveKeyboardLayoutRefresh() async throws {
  let sources = try SmokeInputSources()
  defer { sources.restore() }
  let session = HostInput.KeyboardLayoutSession()
  let initial = try #require(session.layout, "No current keyboard layout available.")
  let initialCode = initial.keyCode(for: "a")
  let useUS = initialCode == kVK_ANSI_Q
  let targetID = useUS ? "com.apple.keylayout.US" : "com.apple.keylayout.French"
  let expectedCode = useUS ? kVK_ANSI_A : kVK_ANSI_Q
  try #require(targetID != sources.originalID, "The current source and layout mapping disagree.")
  try sources.select(targetID)

  let clock = ContinuousClock()
  let deadline = clock.now + .seconds(5)
  while clock.now < deadline {
    // Only read the cache. The session's real notification must update it.
    if session.layout?.keyCode(for: "a") == expectedCode {
      #expect(currentSourceID() == targetID)
      #expect(initial.keyCode(for: "a") == initialCode)
      return
    }
    try await Task.sleep(for: .milliseconds(100))
  }
  Issue.record("Cached layout did not refresh to \(targetID); macOS reports \(currentSourceID() ?? "no selected source").")
}

@MainActor
final class SmokeInputSources {
  private let original: TISInputSource
  let originalID: String
  private var temporary: [TISInputSource] = []

  init() throws {
    let original = try #require(TISCopyCurrentKeyboardInputSource()?.takeRetainedValue())
    self.original = original
    originalID = try #require(sourceID(original))
  }

  func select(_ id: String) throws {
    guard currentSourceID() != id else { return }

    func list(includeDisabled: Bool) -> [TISInputSource]? {
      TISCreateInputSourceList([kTISPropertyInputSourceID: id] as CFDictionary, includeDisabled)?
        .takeRetainedValue() as? [TISInputSource]
    }

    let enabled = try #require(list(includeDisabled: false))
    let target: TISInputSource
    if let existing = enabled.first(where: { sourceID($0) == id }) {
      target = existing
    } else {
      target = try #require(list(includeDisabled: true)?.first(where: { sourceID($0) == id }),
                            "Built-in test input source \(id) was not found.")
      let status = TISEnableInputSource(target)
      try #require(status == noErr, "Could not enable \(id) (status \(status)).")
      temporary.append(target)
    }
    let status = TISSelectInputSource(target)
    try #require(status == noErr, "Could not select \(id) (status \(status)).")
  }

  func restore() {
    if currentSourceID() != originalID {
      let status = TISSelectInputSource(original)
      #expect(status == noErr, "Failed to restore the original input source (status \(status)).")
    }
    let restored = currentSourceID() == originalID
    #expect(restored, "The original input source was not restored.")
    for target in temporary where restored {
      let status = TISDisableInputSource(target)
      #expect(status == noErr, "Failed to disable a temporary input source (status \(status)).")
    }
  }
}

func currentSourceID() -> String? {
  TISCopyCurrentKeyboardInputSource().map { $0.takeRetainedValue() }.flatMap(sourceID)
}

private func sourceID(_ source: TISInputSource) -> String? {
  guard let value = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
  return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
}
