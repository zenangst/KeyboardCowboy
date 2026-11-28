import AppKit
import ApplicationServices
import Testing
import WindowTidyFeature
import WindowTilingFeature

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveWindowTidy() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the terminal running the Window Tidy smoke.")
  let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"]))
  let url = directory.appendingPathComponent("Workspace Fixture A.app").resolvingSymlinksInPath()
  let bundle = "com.zenangst.kc-workspace-fixture-a"
  try #require(Bundle(url: url)?.bundleIdentifier == bundle)
  try #require(NSRunningApplication.runningApplications(withBundleIdentifier: bundle).isEmpty)
  let config = NSWorkspace.OpenConfiguration()
  config.arguments = ["--tidy-fixture"]
  let fixture = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
  try #require(fixture.bundleURL?.resolvingSymlinksInPath() == url)
  defer { _ = fixture.terminate() }
  let pid = fixture.processIdentifier
  func inventory() -> [WindowTidy.Window] {
    let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    return rows.compactMap { row in
      guard row[kCGWindowLayer as String] as? Int == 0,
            row[kCGWindowOwnerPID as String] as? pid_t == pid,
            let id = row[kCGWindowNumber as String] as? CGWindowID,
            let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
            let alpha = row[kCGWindowAlpha as String] as? Double else { return nil }
      return .init(id: id, owner: pid, frame: frame, bundleIdentifier: bundle, alpha: alpha)
    }
  }
  let deadline = ContinuousClock.now + .seconds(4)
  while ContinuousClock.now < deadline, inventory().count != 3 || NSWorkspace.shared.frontmostApplication != fixture {
    try await Task.sleep(for: .milliseconds(100))
  }
  let initial = inventory()
  try #require(initial.count == 3 && NSWorkspace.shared.frontmostApplication == fixture)
  let anchor = try #require(initial.first)
  try #require(anchor.frame.width == 420)
  let other = try #require(initial.first { $0.frame.width == 430 })
  let decoy = try #require(initial.first { $0.frame.width == 160 })
  let primary = try #require(NSScreen.screens.first)
  let visible = try #require(NSScreen.screens.map {
    let frame = $0.visibleFrame
    return CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
  }.first { $0.contains(CGPoint(x: anchor.frame.midX, y: anchor.frame.midY)) })

  let result = try await WindowTidy.runNative(.init(id: "smoke"), inventory: inventory, visibleFrame: visible, spacing: 8)
  #expect(result.applied == [other.id, anchor.id])
  #expect(result.skipped.isEmpty && result.restoredFocus)
  let after = inventory()
  for (window, tile) in [(anchor, WindowTiling.Action.left), (other, .right)] {
    let actual = try #require(after.first { $0.id == window.id })
    #expect(WindowTiling.classify(actual.frame, in: visible, margin: 8) == tile,
            "Window \(window.id): before \(window.frame), after \(actual.frame), display \(visible)")
  }
  #expect(after.first { $0.id == decoy.id }?.frame == decoy.frame)
}
