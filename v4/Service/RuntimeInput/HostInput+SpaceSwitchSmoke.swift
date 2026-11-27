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
    func visibleFixtureOwners() -> Set<pid_t>? {
      guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] else { return nil }
      return Set(rows.compactMap { $0[kCGWindowOwnerPID as String] as? pid_t }).intersection(allowed)
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
          visibleFixtureOwners() == allowed else {
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
    guard try await waitFor({ changes.count > 0 && visibleFixtureOwners() == [] }),
          try await !session.cycleInCurrentSpace(.next) else {
      log.error("No confirmed switch to an empty Space, or ring selected an off-Space window")
      return
    }
    let afterLeaving = changes.count
    try speak("Return to the original desktop. Keep the first fixture app frontmost.")
    guard try await waitFor({
      changes.count > afterLeaving && visibleFixtureOwners() == allowed
        && NSWorkspace.shared.frontmostApplication?.processIdentifier == source
    }) else {
      log.error("No confirmed return to the original Space and fixture anchor")
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
