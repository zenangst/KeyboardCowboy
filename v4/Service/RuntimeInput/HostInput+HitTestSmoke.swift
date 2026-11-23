#if DEBUG
import AccessibilitySystem
import ApplicationServices
import OSLog

package extension HostInput {
  @MainActor
  static func smokeHitTest(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "HitTestSmoke")
    guard arguments.isEmpty else {
      log.notice("Expected --smoke-hit-test with no arguments")
      return
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    log.notice("Move the pointer over the test control within five seconds")
    do {
      try await Task.sleep(for: .seconds(5))
      guard let point = CGEvent(source: nil)?.location else {
        log.error("Could not read the pointer location")
        return
      }

      let onPrimary = CGDisplayBounds(CGMainDisplayID()).contains(point)
      log.notice("AX point: (\(Double(point.x), privacy: .public), \(Double(point.y), privacy: .public)); primary display: \(onPrimary, privacy: .public)")
      let hit = try await captureElement(at: point)
      log.notice("Hit role: \(hit.role?.rawValue ?? "unavailable", privacy: .public)")
      log.notice("AX frame: \(String(describing: hit.frame), privacy: .public); contains pointer: \(hit.frame.contains(point), privacy: .public)")
    } catch let failure as AccessibilitySystem.Failure {
      log.error("Hit test failed: \(failure.operation, privacy: .public) \(String(describing: failure.kind), privacy: .public)")
    } catch {
      log.error("Hit test failed")
    }
  }
}
#endif
