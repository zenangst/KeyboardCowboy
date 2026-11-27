import AppKit
import ApplicationServices
@testable import SystemFeature
import Testing

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SYSTEM_MINIMIZE_FIXTURE"] != nil))
@MainActor
func liveMinimizeAllWindows() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before the live Minimize probe.")
  let fixture = try #require(ProcessInfo.processInfo.environment["KC_SYSTEM_MINIMIZE_FIXTURE"])
  let screen = try #require(NSScreen.screens.first)
  let displayID = try #require(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
  let result = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: result) }

  let config = NSWorkspace.OpenConfiguration()
  config.createsNewApplicationInstance = true
  config.arguments = ["system-minimize", result.path, displayID.stringValue]
  let app = try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: fixture), configuration: config)
  defer { app.terminate() }
  let deadline = ContinuousClock.now + .seconds(5)
  while !FileManager.default.fileExists(atPath: result.path), ContinuousClock.now < deadline {
    try await Task.sleep(for: .milliseconds(100))
  }
  let ids = Set(try String(contentsOf: result, encoding: .utf8).split(separator: " ").compactMap { CGWindowID($0) })
  try #require(ids.count == 2 && !ids.contains(kCGNullWindowID))

  func visibleFixtureWindows() -> Set<CGWindowID> {
    let rows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    return Set(rows.compactMap { row in
      guard row[kCGWindowOwnerPID as String] as? pid_t == app.processIdentifier,
            let id = row[kCGWindowNumber as String] as? CGWindowID, ids.contains(id) else { return nil }

      return id
    })
  }

  let inventoryDeadline = ContinuousClock.now + .seconds(4)
  while visibleFixtureWindows() != ids, ContinuousClock.now < inventoryDeadline {
    try await Task.sleep(for: .milliseconds(100))
  }
  try #require(visibleFixtureWindows() == ids)
  try #require(NSWorkspace.shared.frontmostApplication?.isEqual(app) == true, "Keep the fixture frontmost.")
  let name = try #require(app.localizedName)
  let bundleID = try #require(app.bundleIdentifier)
  let live = SystemFeature.Operation.MinimizeAllWindows.live()
  let operation = SystemFeature.Operation.MinimizeAllWindows(
    windowOwners: { live.windowOwners().filter { $0 == name } },
    applications: { live.applications().filter { $0.pid == app.processIdentifier } },
    // The disposable fixture lives outside the production catalog's search roots.
    catalogBundleIDs: { [bundleID] },
    pressMinimizeAll: live.pressMinimizeAll,
  )
  try #require(!operation.windowOwners().isEmpty)
  try await operation(nil)

  let settleDeadline = ContinuousClock.now + .seconds(4)
  while !visibleFixtureWindows().isEmpty, ContinuousClock.now < settleDeadline {
    try await Task.sleep(for: .milliseconds(100))
  }
  #expect(!app.isTerminated)
  #expect(visibleFixtureWindows().isEmpty)
  let element = AXUIElementCreateApplication(app.processIdentifier)
  var windows: CFTypeRef?
  try #require(AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windows) == .success)
  let appWindows = try #require(windows as? [AXUIElement])
  try #require(appWindows.count == 2)
  for window in appWindows {
    var minimized: CFTypeRef?
    #expect(AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimized) == .success)
    #expect(minimized as? Bool == true)
  }
}
