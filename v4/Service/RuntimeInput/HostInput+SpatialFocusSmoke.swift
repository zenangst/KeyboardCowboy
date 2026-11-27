#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import ApplicationServices
import OSLog
import WindowFocusFeature

package extension HostInput {
  @MainActor
  static func smokeSpatialFocus(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "SpatialFocusSmoke")
    guard arguments.count == 2 || arguments.count == 3, let pid = pid_t(arguments[0]), pid > 0,
          ["center", "quarter", "left", "right", "up", "down", "space-ring", "space-switch"].contains(arguments[1]),
          let app = NSRunningApplication(processIdentifier: pid),
          let screen = NSScreen.main, let primary = NSScreen.screens.first else { return }
    let fixture = "com.zenangst.kc-next-window-fixture"
    let peer = "com.zenangst.kc-next-window-peer"
    var allowed: Set<pid_t> = [pid]
    if arguments.count == 3 {
      guard let otherPID = pid_t(arguments[2]), otherPID > 0, otherPID != pid,
            let other = NSRunningApplication(processIdentifier: otherPID),
            Set([app.bundleIdentifier, other.bundleIdentifier]) == [fixture, peer] else { return }
      allowed.insert(otherPID)
    } else {
      guard app.bundleIdentifier == fixture, !["space-ring", "space-switch"].contains(arguments[1]) else { return }
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    func axFrame(_ frame: CGRect) -> CGRect {
      CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
    }
    // The first PID is the expected anchor; a focus change must not reverse the hop.
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return }
    let session = WindowFocus.SpatialFocus(in: allowed)
    do {
      switch arguments[1] {
      case "center":
        let focused = try await session.center(in: axFrame(screen.frame), visibleFrame: axFrame(screen.visibleFrame))
        log.notice("Center focus observed: \(focused, privacy: .public)")
      case "quarter":
        for _ in 0 ..< 2 {
          let focused = try await session.quarter(.topLeft, in: axFrame(screen.frame))
          log.notice("Quarter focus observed: \(focused, privacy: .public)")
          guard focused else { return }
          try await Task.sleep(for: .milliseconds(150))
        }
      case "space-ring":
        let directions: [WindowFocus.SpaceRing.Direction] = [.next, .next, .next, .previous, .previous]
        for (index, direction) in directions.enumerated() {
          let focused = try await session.cycleInCurrentSpace(direction)
          log.notice("Current-Space ring hop \(index + 1, privacy: .public) observed: \(focused, privacy: .public)")
          guard focused else { return }
          try await Task.sleep(for: .milliseconds(150))
        }
      case "space-switch":
        try await smokeSpaceSwitch(session, source: pid, allowed: allowed)
      default:
        let directions: [String: WindowFocus.DirectionalSearch.Direction] = [
          "left": .left, "right": .right, "up": .up, "down": .down,
        ]
        guard let direction = directions[arguments[1]] else { return }
        let focused = try await session.directional(direction, visibleFrames: NSScreen.screens.map { axFrame($0.visibleFrame) })
        log.notice("Directional focus observed: \(focused, privacy: .public)")
      }
    } catch {
      log.error("Spatial focus smoke failed: \(String(describing: error), privacy: .public)")
    }
  }
}
#endif
