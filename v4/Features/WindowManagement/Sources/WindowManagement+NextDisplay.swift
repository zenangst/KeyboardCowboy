import AccessibilitySystem
import Darwin

public extension WindowManagement {
  /// Moves the application's focused window to the center of the next
  /// display's usable area without resizing or moving the pointer. Display
  /// order is supplied by the caller and wraps. With no alternate usable
  /// display, returns nil and does not move the window.
  @discardableResult
  static func moveFocusedWindowToNextDisplay(
    in processIdentifier: pid_t, displays: [Display],
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    guard processIdentifier > 0, processIdentifier != getpid(), displays.count > 1 else { return nil }
    let operation = Operation.NextDisplay(displays: displays)
    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try Operation.moveFocusedWindow(
        focusedWindow: session.focusedWindow,
        frame: { try session.frame(of: $0) },
        requested: operation.requestedFrame,
        move: { try session.write(.position, value: $0, to: $1) },
      )
    }
  }
}
