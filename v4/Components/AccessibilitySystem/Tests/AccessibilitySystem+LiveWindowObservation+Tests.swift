import AccessibilitySystem
import ApplicationServices
import Foundation
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_AX_WINDOW_OBSERVATION_PID"] != nil))
func liveWindowObservation() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the test runner before starting.")
  let rawPID = try #require(ProcessInfo.processInfo.environment["KC_AX_WINDOW_OBSERVATION_PID"])
  let pid = try #require(Int32(rawPID))
  try #require(pid > 0, "Use the PID of a separate, running test app.")

  let observation = AccessibilitySystem.WindowObservation()
  var first: [AccessibilitySystem.WindowEvent] = []
  var second: [AccessibilitySystem.WindowEvent] = []
  defer { observation.stop() }

  try observation.start(processIdentifier: pid) { first.append($0) }
  try await interact("Observer ready: open a disposable window, switch window focus, then close that window.", seconds: 20)
  try #require(first.contains(.created))
  try #require(first.contains(.focusChanged))
  report("App-level element destruction notifications: \(first.count(where: { $0 == .elementDestroyed })).")

  observation.stop()
  let firstCount = first.count
  try await interact("Observer stopped: open another disposable window and switch focus.", seconds: 10)
  #expect(first.count == firstCount)

  try observation.start(processIdentifier: pid) { second.append($0) }
  try await interact("Observer restarted: open one more disposable window and switch focus.", seconds: 20)
  #expect(second.contains(.created))
  #expect(second.contains(.focusChanged))
  #expect(first.count == firstCount)
}

private func interact(_ instruction: String, seconds: Int) async throws {
  report("\(instruction) You have \(seconds) seconds.")
  try await Task.sleep(for: .seconds(seconds))
}

private func report(_ message: String) {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
}
