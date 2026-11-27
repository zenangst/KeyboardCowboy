#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import ApplicationServices
import OSLog
import WindowFocusFeature

package extension HostInput {
  @MainActor
  static func smokeSpatialFocus(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "SpatialFocusSmoke")
    guard arguments.count == 2, let pid = pid_t(arguments[0]), pid > 0,
          ["center", "quarter", "left", "right", "up", "down"].contains(arguments[1]),
          let app = NSRunningApplication(processIdentifier: pid),
          app.bundleIdentifier == "com.zenangst.kc-next-window-fixture",
          let screen = NSScreen.main, let primary = NSScreen.screens.first else { return }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    func axFrame(_ frame: CGRect) -> CGRect {
      CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
    }
    let session = WindowFocus.SpatialFocus(in: pid)
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
