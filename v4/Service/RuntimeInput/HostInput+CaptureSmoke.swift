#if DEBUG
import AccessibilitySystem
import ApplicationServices
import OSLog

package extension HostInput {
  @MainActor
  static func smokeCapture(
    arguments: [String],
    showInEditor: @MainActor (CapturedElement) async throws -> Void,
  ) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "CaptureSmoke")
    guard arguments.isEmpty || arguments == ["--show-in-editor"] else {
      log.notice("Expected --smoke-capture [--show-in-editor]")
      return
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }
    guard CGPreflightListenEventAccess() else {
      log.notice("Input Monitoring unavailable")
      return
    }

    let session = CaptureSession(signature: 0x4B435634)
    let (finished, completion) = AsyncStream<Void>.makeStream()
    var captured: CapturedElement?
    defer { session.stop() }
    do {
      try session.start(onResult: { result in
        switch result {
        case .success(let hit):
          captured = hit
          log.notice("Captured role: \(hit.role?.rawValue ?? "unavailable", privacy: .public); AX frame: \(String(describing: hit.frame), privacy: .public)")
        case .failure(let error):
          if let failure = error as? AccessibilitySystem.Failure {
            log.error("Capture failed: \(failure.operation, privacy: .public) \(String(describing: failure.kind), privacy: .public)")
          } else {
            log.error("Capture failed")
          }
        }
        completion.finish()
      }, onDisruption: { _ in
        log.error("Capture tap disrupted")
        completion.finish()
      }, onCancel: {
        log.notice("Capture cancelled")
        completion.finish()
      })
    } catch {
      log.error("Could not start capture tap")
      return
    }

    let timeout = Task {
      do {
        try await Task.sleep(for: .seconds(15))
        session.stop()
        log.notice("Capture timed out")
        completion.finish()
      } catch {}
    }
    defer { timeout.cancel() }
    log.notice("Command-click a test control within 15 seconds, or press Escape")
    var iterator = finished.makeAsyncIterator()
    _ = await iterator.next()
    session.stop()
    timeout.cancel()
    if arguments == ["--show-in-editor"], let captured {
      do {
        try await showInEditor(captured)
        log.notice("Opened capture preview in Editor")
      } catch {
        log.error("Could not open capture preview in Editor")
      }
    }
  }
}
#endif
