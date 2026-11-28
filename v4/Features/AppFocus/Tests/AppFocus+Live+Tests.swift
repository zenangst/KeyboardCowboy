import AccessibilitySystem
import AppFocusFeature
import AppKit
import ApplicationCatalog
import ApplicationServices
import Commands
import SystemFeature
import Testing
import WindowTilingFeature

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveAppFocus() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the terminal running the App Focus smoke.")
  let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"]))
  let apps: [ApplicationCatalog.Application] = ["A", "B"].map { name in
    let label = "Workspace Fixture \(name)"
    return .init(bundleIdentifier: "com.zenangst.kc-workspace-fixture-\(name.lowercased())",
                 bundleName: label, path: directory.appendingPathComponent("\(label).app").path)
  }
  for app in apps {
    try #require(Bundle(path: app.path)?.bundleIdentifier == app.bundleIdentifier)
    try #require(NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier).isEmpty)
  }

  func launch(_ fixture: ApplicationCatalog.Application, activates: Bool) async throws -> NSRunningApplication {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = activates
    return try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: fixture.path), configuration: configuration)
  }
  let a = try await launch(apps[0], activates: true)
  defer { _ = a.terminate() }
  let b = try await launch(apps[1], activates: false)
  defer { _ = b.terminate() }
  let allowed = Set([a.processIdentifier, b.processIdentifier])
  let primary = try #require(NSScreen.screens.first)
  func global(_ frame: CGRect) -> CGRect {
    .init(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
  }
  func process(_ app: NSRunningApplication) -> AppFocus.Snapshot.Process? {
    guard let bundle = app.bundleIdentifier else { return nil }
    return .init(bundleIdentifier: bundle, pid: app.processIdentifier)
  }
  func snapshot() -> AppFocus.Snapshot {
    let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    let windows: [AppFocus.Window] = rows.compactMap { row in
      guard row[kCGWindowLayer as String] as? Int == 0,
            let pid = row[kCGWindowOwnerPID as String] as? pid_t, allowed.contains(pid),
            let id = row[kCGWindowNumber as String] as? CGWindowID,
            let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
            let alpha = row[kCGWindowAlpha as String] as? Double else { return nil }
      return .init(id: id, owner: pid, frame: frame, alpha: alpha)
    }
    return .init(frontmost: NSWorkspace.shared.frontmostApplication.flatMap(process),
                 running: NSWorkspace.shared.runningApplications.filter { !$0.isTerminated }.compactMap(process),
                 windows: windows, displays: NSScreen.screens.map { global($0.visibleFrame) }, tilingMargin: 8)
  }
  let deadline = ContinuousClock.now + .seconds(4)
  while ContinuousClock.now < deadline, snapshot().windows.count != 2 || NSWorkspace.shared.frontmostApplication != a {
    try await Task.sleep(for: .milliseconds(100))
  }
  try #require(snapshot().windows.count == 2 && NSWorkspace.shared.frontmostApplication == a)
  let initial = try #require(snapshot().windows.first { $0.owner == b.processIdentifier })
  try #require(abs(initial.frame.width - 420) <= 1, "Fixture must start untiled.")
  let visible = try #require(snapshot().displays.first { $0.contains(CGPoint(x: initial.frame.midX, y: initial.frame.midY)) })
  let client = AccessibilitySystem.Client()
  var effects: [String] = []
  let executor = AppFocus.Executor(
    snapshot: snapshot,
    open: { _ in Issue.record("The running target already has an eligible window") },
    activateAll: { target in
      try #require(target.pid == b.processIdentifier && NSWorkspace.shared.frontmostApplication == a)
      if !b.activate(from: a, options: .activateAllWindows) {
        // A command-line runner does not own foreground activation.
        // Ask Launch Services to reactivate the existing fixture, not a new process.
        let reopened = try await launch(apps[1], activates: true)
        try #require(reopened == b)
      }
      effects.append("activate")
    },
    hideOtherApps: { target in
      try #require(target.pid == b.processIdentifier && NSWorkspace.shared.frontmostApplication == b)
      try await SystemCommand.hideAllApps(workflowApplications: [.init(application: apps[1])], limitingTo: allowed)
      try #require(a.isHidden && !a.isTerminated && !b.isHidden)
      effects.append("hide")
    },
    tile: { action, target in
      try #require(action == .fill && target.pid == b.processIdentifier)
      try #require(try await WindowTiling.execute(action, onFocusedWindow: initial.id, of: b, using: client))
      effects.append("fill")
    },
  )
  let outcome = try await executor.run(
    .init(bundleIdentifier: "*.*.previous", hideOtherApps: true, tiling: .arrangeLeftRight),
    catalog: apps, previous: apps[1],
  )
  try #require(outcome == .completed)
  #expect(effects == ["activate", "hide", "fill"])
  var actual: CGRect?
  for _ in 0 ..< 20 {
    actual = snapshot().windows.first { $0.id == initial.id && $0.owner == b.processIdentifier }?.frame
    if actual.map({ WindowTiling.classify($0, in: visible, margin: 8) == .fill }) == true { break }
    try await Task.sleep(for: .milliseconds(100))
  }
  #expect(actual.map { WindowTiling.classify($0, in: visible, margin: 8) } == .fill)
  #expect(a.isHidden && !b.isHidden && NSWorkspace.shared.frontmostApplication == b)
}
