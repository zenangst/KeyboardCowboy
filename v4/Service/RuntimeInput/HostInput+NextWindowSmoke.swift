#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import ApplicationServices
import OSLog
import WindowFocusFeature

package extension HostInput {
  @MainActor
  static func smokeWindowFocus(previous: Bool, arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "WindowFocusSmoke")
    guard let first = arguments.first, let pid = pid_t(first), pid > 0,
          arguments.count == 1 || (previous && arguments.count == 3) else {
      log.notice("Expected --smoke-next-window <pid> or --smoke-previous-window <pid> [<current-id> <previous-id>]")
      return
    }

    var history: WindowFocus.History?
    if arguments.count == 3 {
      guard let current = CGWindowID(arguments[1]), let prior = CGWindowID(arguments[2]), current != 0, prior != 0 else {
        log.notice("Expected nonzero current and previous window IDs")
        return
      }

      history = .init(processIdentifier: pid, current: current, previous: prior)
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    do {
      let isActive: @Sendable () -> Bool = {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
      }
      let observed = if previous {
        try await WindowFocus.previousWindow(in: pid, history: history, isAppActive: isActive)
      } else {
        try await WindowFocus.nextWindow(in: pid, isAppActive: isActive)
      }
      let command = previous ? "Previous" : "Next"
      log.notice("\(command, privacy: .public) window focus succeeded: \(observed, privacy: .public)")
    } catch let error {
      log.error("Window focus smoke failed: \(String(describing: error), privacy: .public)")
    }
  }
}
#endif
