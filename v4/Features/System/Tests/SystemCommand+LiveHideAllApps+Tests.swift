import AppKit
@testable import SystemFeature
import Testing

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SYSTEM_HIDE_FIXTURE"] != nil))
@MainActor
func liveHideAllApps() async throws {
  let fixture = try #require(ProcessInfo.processInfo.environment["KC_SYSTEM_HIDE_FIXTURE"])
  let screen = try #require(NSScreen.screens.first)
  let displayID = try #require(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
  let result = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: result) }

  let config = NSWorkspace.OpenConfiguration()
  config.createsNewApplicationInstance = true
  config.arguments = ["resizable", result.path, displayID.stringValue]
  let app = try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: fixture), configuration: config)
  defer { app.terminate() }
  let pid = app.processIdentifier
  let live = SystemFeature.Operation.HideAllApps.live()
  let operation = SystemFeature.Operation.HideAllApps(
    screens: live.screens,
    applications: { live.applications().filter { $0.pid == pid } },
    windows: { live.windows().filter { $0.pid == pid } },
    ownBundleID: live.ownBundleID,
    ownPID: live.ownPID,
    pause: live.pause,
  )

  let deadline = ContinuousClock.now + .seconds(5)
  while (!FileManager.default.fileExists(atPath: result.path) || operation.windows().isEmpty),
        ContinuousClock.now < deadline {
    try await Task.sleep(for: .milliseconds(100))
  }
  try #require(FileManager.default.fileExists(atPath: result.path))
  try #require(!operation.windows().isEmpty)
  try #require(NSWorkspace.shared.frontmostApplication?.isEqual(app) == true, "Keep the fixture frontmost.")
  try #require(!app.isHidden && !app.isTerminated)

  try await operation([])

  #expect(!app.isTerminated)
  #expect(app.isHidden)
  #expect(operation.windows().isEmpty)
}
