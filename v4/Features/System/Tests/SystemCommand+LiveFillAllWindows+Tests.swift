import AppKit
import ApplicationServices
@testable import SystemFeature
import Testing

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SYSTEM_FILL_FIXTURE"] != nil))
@MainActor
func liveFillAllWindows() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before the live Fill probe.")
  let fixture = try #require(ProcessInfo.processInfo.environment["KC_SYSTEM_FILL_FIXTURE"])
  let primary = try #require(NSScreen.screens.first)
  let screenNumber = NSDeviceDescriptionKey("NSScreenNumber")
  let displayID = try #require(primary.deviceDescription[screenNumber] as? NSNumber)
  let expectedWindowCount = NSScreen.screens.count > 1 ? 3 : 2
  let result = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: result) }

  let config = NSWorkspace.OpenConfiguration()
  config.createsNewApplicationInstance = true
  config.arguments = ["system-fill", result.path, displayID.stringValue]
  let app = try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: fixture), configuration: config)
  defer { app.terminate() }
  let deadline = ContinuousClock.now + .seconds(5)
  while !FileManager.default.fileExists(atPath: result.path), ContinuousClock.now < deadline {
    try await Task.sleep(for: .milliseconds(100))
  }
  let ids = try String(contentsOf: result, encoding: .utf8).split(separator: " ").compactMap { CGWindowID($0) }
  let allowedIDs = Set(ids)
  try #require(ids.count == expectedWindowCount && allowedIDs.count == ids.count && !allowedIDs.contains(kCGNullWindowID))
  let primaryIDs = ids.prefix(2)
  let controlID = ids.dropFirst(2).first
  try #require(NSWorkspace.shared.frontmostApplication?.isEqual(app) == true, "Keep the fixture frontmost.")
  try #require(NSScreen.main?.deviceDescription[screenNumber] as? NSNumber == displayID)

  func frames() -> [CGWindowID: CGRect] {
    let rows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
      guard let id = row[kCGWindowNumber as String] as? CGWindowID,
            row[kCGWindowOwnerPID as String] as? pid_t == app.processIdentifier, allowedIDs.contains(id),
            let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return nil }

      return (id, frame)
    })
  }

  let live = SystemFeature.Operation.FillAllWindows.live()
  let operation = SystemFeature.Operation.FillAllWindows(
    display: live.display,
    windows: { live.windows().filter { $0.pid == app.processIdentifier && allowedIDs.contains($0.id) } },
    fill: live.fill,
  )
  let display = try #require(operation.display())
  let bounds = display.visibleBounds
  let inventoryDeadline = ContinuousClock.now + .seconds(4)
  var before = frames()
  while before.count != ids.count, ContinuousClock.now < inventoryDeadline {
    try await Task.sleep(for: .milliseconds(100))
    before = frames()
  }
  try #require(before.count == ids.count)
  for id in primaryIDs {
    let frame = try #require(before[id])
    try #require(bounds.contains(frame) && !isFilled(frame, in: bounds, configuredMargin: display.spacing))
  }
  if let id = controlID {
    let frame = try #require(before[id])
    try #require(!bounds.intersects(frame))
    try #require(abs(frame.width - 420) <= 2, "The secondary control must start untiled.")
  }

  try await operation()
  let settleDeadline = ContinuousClock.now + .seconds(3)
  while ContinuousClock.now < settleDeadline {
    let after = frames()
    if primaryIDs.allSatisfy({ after[$0].map { isFilled($0, in: bounds, configuredMargin: display.spacing) } ?? false }) {
      if let id = controlID { #expect(after[id] == before[id]) }
      print("Native Fill: configured margin \(display.spacing); settled frames \(after); secondary control \(String(describing: controlID)).")
      return
    }
    try await Task.sleep(for: .milliseconds(100))
  }
  Issue.record("Fixture windows did not fill \(bounds). Before: \(before); after: \(frames()).")
}

private func isFilled(_ frame: CGRect, in bounds: CGRect, configuredMargin: CGFloat) -> Bool {
  // macOS can apply its native margin rather than the value read from preferences.
  let edges = [frame.minX - bounds.minX, frame.minY - bounds.minY,
               bounds.maxX - frame.maxX, bounds.maxY - frame.maxY]
  let margin = edges[0]
  return margin >= -2 && margin <= max(configuredMargin, 8) + 2
    && edges.allSatisfy { abs($0 - margin) <= 2 }
}
