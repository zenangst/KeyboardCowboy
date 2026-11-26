import AccessibilitySystem
import Darwin

public extension WindowManagement {
  typealias CenterResult = FrameResult

  /// Centers the specified application's focused window without resizing it.
  /// Returns nil if no display intersects the window or the target is unavailable.
  @discardableResult
  static func centerFocusedWindow(
    in processIdentifier: pid_t, displays: [Display],
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CenterResult? {
    // AX can call an in-process AppKit setter inline on the off-main worker.
    guard processIdentifier > 0, processIdentifier != getpid(), !displays.isEmpty else { return nil }

    let center = Operation.Center(displays: displays)
    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try center(
        focusedWindow: session.focusedWindow,
        frame: { try session.frame(of: $0) },
        move: { try session.write(.position, value: $0, to: $1) },
      )
    }
  }
}
