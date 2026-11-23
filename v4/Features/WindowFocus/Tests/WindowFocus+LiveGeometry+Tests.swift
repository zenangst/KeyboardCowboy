import AccessibilitySystem
import AppKit
import CoreGraphics
import Testing

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WINDOW_GEOMETRY_SMOKE"] == "1"))
func comparesLiveAXAndCGGeometryAgainstOwnedWindowNumbers() async throws {
  let app = NSApplication.shared
  app.setActivationPolicy(.accessory)
  app.finishLaunching()
  let screen = try #require(NSScreen.screens.first)
  let start = CGRect(x: screen.visibleFrame.minX + 40, y: screen.visibleFrame.minY + 80, width: 300, height: 200)
  let other = start.offsetBy(dx: 80, dy: 40)
  let names = ["Window Geometry Fixture A", "Window Geometry Fixture B"]
  let windows = zip(names, [start, other]).map { title, rect in
    let window = NSWindow(contentRect: rect, styleMask: [.titled], backing: .buffered, defer: false)
    window.title = title
    window.isReleasedWhenClosed = false
    window.orderFrontRegardless()
    return window
  }
  defer { windows.forEach { $0.close() } }

  let pid = getpid()
  let client = AccessibilitySystem.Client()
  func axFrames() async throws -> [CGRect] {
    try await client.withApplication(processIdentifier: pid) { session in
      let windows = try session.windows()
      // Names label our own ground-truth fixtures; the comparison never receives titles.
      return try names.map { name in
        let window = try #require(windows.first { try session.read(.title, of: $0) == name })
        return try CGRect(origin: session.read(.position, of: window), size: session.read(.size, of: window))
      }
    }
  }

  func cgWindows() throws -> [GeometryEvidence.CGWindow] {
    let rows = try #require(CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]])
    return rows.compactMap { row in
      guard let owner = row[kCGWindowOwnerPID as String] as? pid_t, owner == pid,
            let id = row[kCGWindowNumber as String] as? CGWindowID,
            let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return nil }
      return .init(id: id, pid: owner, frame: frame)
    }
  }

  let ids = try windows.map { try #require(CGWindowID(exactly: $0.windowNumber)) }
  try #require(ids.allSatisfy { $0 != kCGNullWindowID } && ids[0] != ids[1])
  try await Task.sleep(for: .milliseconds(200))
  let distinctAX = try await axFrames()
  #expect(try GeometryEvidence.assess(axFrames: distinctAX, pid: pid, cgWindows: cgWindows())
    == ids.map(GeometryEvidence.candidate))

  let first = windows[0].frame
  windows[0].setFrame(windows[1].frame, display: false)
  windows[1].setFrame(first, display: false)
  try await Task.sleep(for: .milliseconds(200))
  #expect(windows.map(\.windowNumber) == ids.map(Int.init))
  let swappedCG = try cgWindows()
  // Both snapshots are individually unambiguous, but their pairing is wrong.
  #expect(GeometryEvidence.assess(axFrames: distinctAX, pid: pid, cgWindows: swappedCG)
    == ids.reversed().map(GeometryEvidence.candidate))
  let swappedAX = try await axFrames()
  #expect(GeometryEvidence.assess(axFrames: swappedAX, pid: pid, cgWindows: swappedCG)
    == ids.map(GeometryEvidence.candidate))

  windows[1].setFrame(windows[0].frame, display: false)
  try await Task.sleep(for: .milliseconds(200))
  let overlappingAX = try await axFrames()
  #expect(overlappingAX[0] == overlappingAX[1])
  #expect(try GeometryEvidence.assess(axFrames: overlappingAX, pid: pid, cgWindows: cgWindows())
    == [.ambiguous, .ambiguous])
}
