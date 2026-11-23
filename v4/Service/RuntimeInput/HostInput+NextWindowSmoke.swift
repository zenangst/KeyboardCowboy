#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import ApplicationServices
import OSLog
import WindowFocusFeature

package extension HostInput {
  @MainActor
  static func smokeNextWindow(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "WindowFocusSmoke")
    guard arguments.count == 1, let pid = pid_t(arguments[0]), pid > 0 else {
      log.notice("Expected --smoke-next-window <active-app-pid>")
      return
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    do {
      let raised = try await WindowFocus.nextWindow(in: pid) {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
      }
      log.notice("Next window raise succeeded: \(raised, privacy: .public)")
    } catch let error {
      log.error("Next window failed: \(String(describing: error), privacy: .public)")
    }
  }
}
#endif
