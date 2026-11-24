import AccessibilitySystem
import AppKit
import ApplicationServices
import Testing
import WindowTilingFeature

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_TILING_DYNAMIC_SMOKE"] == "1"))
func liveDynamicQuarters() async throws {
  enum SmokeFailure: Error { case layoutTimeout }
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the smoke runner.")
  let app = try #require(NSWorkspace.shared.frontmostApplication, "Leave Finder frontmost.")
  try #require(app.bundleIdentifier == "com.apple.finder", "Leave a disposable Finder window focused.")
  let primary = try #require(NSScreen.screens.first)
  let secondary = try #require(NSScreen.screens.dropFirst().first)
  func global(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY, width: rect.width, height: rect.height)
  }
  let display = global(secondary.frame)
  let visible = global(secondary.visibleFrame)
  let pid = app.processIdentifier
  let client = AccessibilitySystem.Client()
  func frames() throws -> [CGWindowID: CGRect] {
    let rows = try #require(CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]])
    var result: [CGWindowID: CGRect] = [:]
    for row in rows where row[kCGWindowLayer as String] as? Int == 0 {
      guard let bounds = row[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
            frame.intersects(display) else { continue }

      try #require(display.contains(frame) && row[kCGWindowOwnerPID as String] as? pid_t == pid,
                   "Keep only the four disposable Finder windows on the second display.")
      let id = try #require(row[kCGWindowNumber as String] as? CGWindowID)
      result[id] = frame
    }
    return result
  }
  func focusedID() async throws -> CGWindowID? {
    try await client.withApplication(processIdentifier: pid) { session in
      guard let window = try session.focusedWindow() else { return nil }

      return try session.windowIDCandidate(for: window)
    }
  }
  let ids = Set(try frames().keys)
  try #require(ids.count == 4, "Open exactly four disposable Finder windows on the second display.")
  func checkWindows() throws -> [CGWindowID: CGRect] {
    try #require(NSWorkspace.shared.frontmostApplication?.isEqual(app) == true, "Finder lost foreground focus.")
    let current = try frames()
    try #require(Set(current.keys) == ids, "The secondary-display window set changed.")
    return current
  }
  func classify(_ frame: CGRect) -> WindowTiling.Action? {
    WindowTiling.classify(frame, in: visible, margin: 8)
  }
  func waitForLayout(_ matches: ([CGWindowID: CGRect]) -> Bool) async throws -> [CGWindowID: CGRect] {
    var previous: [CGWindowID: CGRect]?
    for _ in 0 ..< 20 {
      let current = try checkWindows()
      if current == previous, matches(current) { return current }
      previous = current
      try await Task.sleep(for: .milliseconds(100))
    }
    Issue.record("Native layout did not settle: \(String(describing: previous))")
    throw SmokeFailure.layoutTimeout
  }
  let initial = try #require(try await focusedID())
  try #require(ids.contains(initial))
  _ = try checkWindows()
  let seeded = try await WindowTiling.execute(.arrangeQuarters, in: pid, eligibleWindowCount: ids.count, using: client)
  try #require(seeded)
  let quarters: Set<WindowTiling.Action> = [.topLeft, .bottomLeft, .topRight, .bottomRight]
  _ = try await waitForLayout { Set($0.values.compactMap(classify)) == quarters }

  typealias Action = WindowTiling.Action
  let cases: [(Action, Action, Action, Set<Action>)] = [
    (.topLeft, .left, .arrangeLeftQuarters, [.topRight, .bottomRight]),
    (.topRight, .right, .arrangeRightQuarters, Set([.topLeft, .bottomLeft])),
  ]
  for (start, half, expected, opposite) in cases {
    let current = try checkWindows()
    let id = try #require(current.keys.sorted().first { current[$0].flatMap(classify) == start })
    try await client.withApplication(processIdentifier: pid) { session in
      let window = try #require(try session.windows().first { try session.windowIDCandidate(for: $0) == id })
      try #require(NSWorkspace.shared.frontmostApplication?.isEqual(app) == true)
      try session.write(.main, value: true, to: window)
      try session.perform(.raise, on: window)
    }
    let focused = try await focusedID()
    try #require(focused == id, "Could not focus the intended Finder window.")
    _ = try checkWindows()
    let action = try await WindowTiling.arrangeDynamicQuarters(
      in: pid, eligibleWindowCount: ids.count, visibleBounds: visible, margin: 8, using: client,
    )
    try #require(action == expected)
    let settled = try await waitForLayout {
      $0[id].flatMap(classify) == half && opposite.isSubset(of: Set($0.values.compactMap(classify)))
    }
    print("Dynamic Quarters \(start.rawValue) → \(expected.rawValue): \(settled)")
  }
}
