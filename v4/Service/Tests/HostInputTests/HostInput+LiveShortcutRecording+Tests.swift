import ApplicationServices
import Foundation
import HostInput
import KeyboardFeature
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SHORTCUT_RECORDING_SMOKE"] == "1"))
func liveShortcutRecording() async throws {
  enum Outcome: Equatable { case matched, unexpectedShortcut, cancelled, disrupted, timedOut }

  try #require(CGPreflightListenEventAccess(), "Grant Input Monitoring to the runner before starting.")
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before starting.")
  let layouts = HostInput.KeyboardLayoutSession()
  try #require(layouts.layout?.keyCode(for: "a") != nil, "Use a layout with an unmodified A key.")

  let session = HostInput.ShortcutRecordingSession(signature: 0x4B43_5634, layouts: layouts)
  let (outcomes, continuation) = AsyncStream<Outcome>.makeStream(bufferingPolicy: .bufferingOldest(1))
  try session.start(onShortcut: { shortcut in
    // Compare to the test chord in memory; never emit the captured shortcut.
    let matched = shortcut.key == "a" && shortcut.modifiers == [.leftShift]
    continuation.yield(matched ? .matched : .unexpectedShortcut)
  }, onDisruption: { _ in
    continuation.yield(.disrupted)
  }, onCancel: {
    continuation.yield(.cancelled)
  })

  let timeout = Task {
    do {
      try await Task.sleep(for: .seconds(20))
      continuation.yield(.timedOut)
    } catch is CancellationError {}
  }
  defer {
    timeout.cancel()
    session.stop()
    continuation.finish()
  }
  FileHandle.standardError.write(Data("Recorder ready: press Left Shift+A in the disposable text field within 20 seconds.\n".utf8))
  var iterator = outcomes.makeAsyncIterator()
  let outcome = await iterator.next()
  #expect(outcome == .matched)
}
