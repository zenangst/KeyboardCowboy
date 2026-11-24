import AccessibilitySystem
import Darwin

public extension WindowManagement {
  enum DisplayTransferMode: Sendable {
    /// Centers in the destination's usable area without resizing.
    case center
    /// Scales position and size relative to both displays' usable areas,
    /// then fits the requested frame inside the destination.
    case relative
  }

  /// Cycles through the supplied display order without moving the pointer.
  /// Relative mode requires a verified, on-screen window in the active app
  /// and waits for its move to settle before resizing. Returns nil if there
  /// is no usable destination or the target cannot be verified. A completed
  /// move is not rolled back if verification fails before resizing.
  @discardableResult
  static func moveFocusedWindowToNextDisplay(
    in processIdentifier: pid_t, displays: [Display], mode: DisplayTransferMode = .center,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    guard processIdentifier > 0, processIdentifier != getpid(), displays.count > 1 else { return nil }
    let operation = Operation.NextDisplay(displays: displays, mode: mode)
    if case .relative = mode {
      return try await placeFocusedWindow(in: processIdentifier, using: accessibility, requestedFrame: operation.requestedFrame)
    }
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
