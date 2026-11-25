import ApplicationServices
import Foundation
@testable import HostInput
import KeyboardFeature
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SHORTCUT_RECORDING_SMOKE"] == "1"))
func liveShortcutRecording() throws {
  enum Outcome: Equatable {
    case matched
    case unexpectedShortcut(keyMatched: Bool, modifiersMatched: Bool)
    case cancelled, disrupted, timedOut
  }

  try #require(CGPreflightListenEventAccess(), "Grant Input Monitoring to the runner before starting.")
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before starting.")
  let layouts = HostInput.KeyboardLayoutSession()
  let keyCode = try #require(layouts.layout?.keyCode(for: "a"), "Use a layout with an unmodified A key.")
  let signature: Int64 = 0x4B43_5634
  let taps = HostInput.TapSession(signature: signature)
  var sawKeyDown = false
  var sawExpectedChord = false
  var disrupted = false
  try taps.startCapture(eventMask: 1 << CGEventType.keyDown.rawValue, handler: { event in
    guard !event.isRepeat else { return .passThrough }

    sawKeyDown = true
    if event.keyCode == Int64(keyCode), event.event.flags.contains(.maskShift) {
      sawExpectedChord = true
    }
    return .passThrough
  }, onDisruption: { _ in disrupted = true })
  cue("Capture ready. Focus the blank TextEdit document. Hold left Shift and tap A once. Release Shift and wait.")
  serviceRunLoop(seconds: 25) { sawExpectedChord || disrupted }
  taps.stopCapture()
  #expect(!disrupted)
  #expect(sawKeyDown, "No non-repeating key-down reached Service capture.")
  try #require(sawExpectedChord, "The expected A key with Shift did not reach Service capture.")
  serviceRunLoop(seconds: 3) { false }

  let session = HostInput.ShortcutRecordingSession(signature: signature, layouts: layouts)
  var outcome: Outcome?
  try session.start(onShortcut: { shortcut in
    // Compare to the test chord in memory; never emit the captured shortcut.
    let keyMatched = shortcut.key == "a"
    let modifiersMatched = shortcut.modifiers == [.leftShift]
    outcome = keyMatched && modifiersMatched
      ? .matched
      : .unexpectedShortcut(keyMatched: keyMatched, modifiersMatched: modifiersMatched)
  }, onDisruption: { _ in
    outcome = .disrupted
  }, onCancel: {
    outcome = .cancelled
  })
  defer { session.stop() }
  cue("Recorder ready. Hold left Shift and tap A once more in TextEdit. Release Shift and wait for the result.")
  serviceRunLoop(seconds: 25) { outcome != nil }
  #expect((outcome ?? .timedOut) == .matched)
}

@MainActor
private func serviceRunLoop(seconds: Int, until done: () -> Bool) {
  let deadline = ContinuousClock.now + .seconds(seconds)
  while ContinuousClock.now < deadline && !done() {
    if CFRunLoopRunInMode(.defaultMode, 0.05, false) == .finished {
      Thread.sleep(forTimeInterval: 0.05)
    }
  }
}

@MainActor
private func cue(_ message: String) {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
  let speech = Process()
  speech.executableURL = URL(filePath: "/usr/bin/say")
  speech.arguments = [message]
  if (try? speech.run()) != nil { serviceRunLoop(seconds: 15) { !speech.isRunning } }
}
