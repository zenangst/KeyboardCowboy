import AppKit
import ApplicationServices
import Testing
import WindowTidyFeature
import WindowTilingFeature

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveWindowTidy() async throws {
  try await verifyLiveTidy(names: ["A"])
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveMultiAppWindowTidy() async throws {
  try await verifyLiveTidy(names: ["A", "B"])
}

@MainActor private func verifyLiveTidy(names: [String]) async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the terminal running the Window Tidy smoke.")
  let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"]))
  var fixtures: [NSRunningApplication] = []
  defer { fixtures.forEach { _ = $0.terminate() } }
  var owners: [pid_t: String] = [:]
  func inventory() -> [WindowTidy.Window] {
    let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    return rows.compactMap { row in
      guard row[kCGWindowLayer as String] as? Int == 0,
            let pid = row[kCGWindowOwnerPID as String] as? pid_t, let bundle = owners[pid],
            let id = row[kCGWindowNumber as String] as? CGWindowID,
            let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
            let alpha = row[kCGWindowAlpha as String] as? Double else { return nil }
      return .init(id: id, owner: pid, frame: frame, bundleIdentifier: bundle, alpha: alpha)
    }
  }
  for (index, name) in names.enumerated() {
    let url = directory.appendingPathComponent("Workspace Fixture \(name).app").resolvingSymlinksInPath()
    let bundle = "com.zenangst.kc-workspace-fixture-\(name.lowercased())"
    try #require(Bundle(url: url)?.bundleIdentifier == bundle)
    try #require(NSRunningApplication.runningApplications(withBundleIdentifier: bundle).isEmpty)
    let config = NSWorkspace.OpenConfiguration()
    config.arguments = ["--tidy-fixture"]
    let fixture = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
    try #require(fixture.bundleURL?.resolvingSymlinksInPath() == url)
    fixtures.append(fixture)
    owners[fixture.processIdentifier] = bundle
    let count = (index + 1) * 3
    let deadline = ContinuousClock.now + .seconds(4)
    while ContinuousClock.now < deadline, inventory().count != count || NSWorkspace.shared.frontmostApplication != fixture {
      try await Task.sleep(for: .milliseconds(100))
    }
    try #require(inventory().count == count && NSWorkspace.shared.frontmostApplication == fixture)
  }
  let initial = inventory()
  let frontmost = try #require(fixtures.last)
  let anchor = try #require(initial.first)
  try #require(anchor.frame.width == 420 && anchor.owner == frontmost.processIdentifier)
  let decoys = initial.filter { $0.frame.width == 160 }
  try #require(decoys.count == names.count)
  let primary = try #require(NSScreen.screens.first)
  let visible = try #require(NSScreen.screens.map {
    let frame = $0.visibleFrame
    return CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
  }.first { $0.contains(CGPoint(x: anchor.frame.midX, y: anchor.frame.midY)) })

  let targets = initial.filter { $0.frame.width == 420 || $0.frame.width == 430 }
  try #require(targets.count == 2 * names.count && targets.allSatisfy { visible.contains($0.frame) })
  let assignments: [(WindowTidy.Window, WindowTiling.Action)]
  let rules: [WindowTidy.Rule]
  if names.count == 1 {
    let other = try #require(targets.last)
    assignments = [(other, .right), (anchor, .left)]
    rules = []
  } else {
    try #require(targets.allSatisfy { WindowTiling.classify($0.frame, in: visible, margin: 8) == nil },
                 "The multi-app fixture windows must start freely placed.")
    let a = try #require(fixtures.first?.processIdentifier)
    let bundle = try #require(owners[a])
    let aBack = try #require(targets.first { $0.owner == a && $0.frame.width == 430 })
    let aFront = try #require(targets.first { $0.owner == a && $0.frame.width == 420 })
    let bBack = try #require(targets.first { $0.owner == anchor.owner && $0.frame.width == 430 })
    try #require(targets.map(\.id) == [anchor.id, bBack.id, aFront.id, aBack.id])
    assignments = [(aBack, .topLeft), (aFront, .bottomLeft), (bBack, .topRight), (anchor, .bottomRight)]
    rules = [.init(bundleIdentifier: bundle, tiling: .topLeft)]
  }
  let result = try await WindowTidy.runNative(
    .init(id: "smoke", rules: rules), inventory: inventory, visibleFrame: visible, spacing: 8,
  )
  #expect(result.applied == assignments.map { $0.0.id })
  #expect(result.skipped.isEmpty && result.restoredFocus)
  #expect(NSWorkspace.shared.frontmostApplication == frontmost)
  let after = inventory()
  for (window, tile) in assignments {
    let actual = try #require(after.first { $0.id == window.id })
    #expect(WindowTiling.classify(actual.frame, in: visible, margin: 8) == tile,
            "Window \(window.id): before \(window.frame), after \(actual.frame), display \(visible)")
  }
  for decoy in decoys {
    #expect(after.first { $0.id == decoy.id }?.frame == decoy.frame)
  }
}
