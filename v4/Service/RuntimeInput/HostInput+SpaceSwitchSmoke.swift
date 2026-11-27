#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import CoreGraphics
import OSLog

import WindowFocusFeature

package extension HostInput {
  @MainActor
  static func smokeSpaceSwitch(
    _ session: WindowFocus.SpatialFocus, source: pid_t, allowed: Set<pid_t>,
  ) async throws {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "SpatialFocusSmoke")
    func speak(_ message: String) throws {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
      process.arguments = [message]
      try process.run()
    }
    func visibleFixtureWindows() -> [CGWindowID: pid_t]? {
      guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] else { return nil }
      var result: [CGWindowID: pid_t] = [:]
      for row in rows {
        guard row[kCGWindowLayer as String] as? Int == 0,
              let owner = row[kCGWindowOwnerPID as String] as? pid_t, allowed.contains(owner),
              let id = row[kCGWindowNumber as String] as? CGWindowID else { continue }
        result[id] = owner
      }
      return result
    }
    func waitFor(_ condition: () -> Bool) async throws -> Bool {
      let deadline = ContinuousClock.now + .seconds(45)
      while ContinuousClock.now < deadline {
        if condition() { return true }
        try await Task.sleep(for: .milliseconds(100))
      }
      return false
    }

    guard try await session.cycleInCurrentSpace(.next),
          try await session.cycleInCurrentSpace(.previous),
          NSWorkspace.shared.frontmostApplication?.processIdentifier == source,
          let baseline = visibleFixtureWindows(), baseline.count == 3, Set(baseline.values) == allowed else {
      log.error("Could not prime Space-switch history")
      return
    }

    // Exercise the host reset contract without adding a production subscription.
    // Keep this baseline on the main actor, like the focus session.
    let changes = SpaceChanges()
    let center = NSWorkspace.shared.notificationCenter
    let observer = center.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { _ in
      MainActor.assumeIsolated {
        changes.count += 1
        session.reset()
      }
    }
    defer { center.removeObserver(observer) }

    try speak("Space switch test ready. Switch to an empty desktop on this display. Wait for the next instruction.")
    guard try await waitFor({
      guard changes.count > 0, let visible = visibleFixtureWindows() else { return false }
      return baseline.keys.allSatisfy { visible[$0] == nil }
    }) else {
      let visible = visibleFixtureWindows()
      let remaining = visible.map { current in baseline.keys.filter { current[$0] != nil }.count } ?? -1
      log.error("Space departure timed out: \(changes.count) notifications, \(remaining) of 3 tracked windows still on-screen (-1 means inventory unavailable)")
      return
    }
    guard try await !session.cycleInCurrentSpace(.next) else {
      log.error("Ring unexpectedly selected a window on the empty Space")
      return
    }
    let afterLeaving = changes.count
    try speak("Return to the original desktop. Keep the first fixture app frontmost.")
    guard try await waitFor({
      changes.count > afterLeaving && visibleFixtureWindows() == baseline
        && NSWorkspace.shared.frontmostApplication?.processIdentifier == source
    }) else {
      let visible = visibleFixtureWindows()
      let restored = visible.map { current in baseline.filter { current[$0.key] == $0.value }.count } ?? -1
      let sourceActive = NSWorkspace.shared.frontmostApplication?.processIdentifier == source
      log.error("Space return timed out: \(changes.count - afterLeaving) notifications, \(restored) of 3 tracked windows restored, source active: \(sourceActive)")
      return
    }

    let focused = try await session.cycleInCurrentSpace(.previous)
    log.notice("Previous after Space reset observed: \(focused, privacy: .public)")
  }

  @MainActor
  private final class SpaceChanges {
    var count = 0
  }
}
#endif
