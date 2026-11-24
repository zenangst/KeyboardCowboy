import AccessibilitySystem
import CoreGraphics
import Darwin

public extension WindowManagement {
  /// Fills the current display's usable area with a symmetric inset in points.
  /// Does not enter native fullscreen or save/restore an earlier frame.
  /// Returns nil when there is no target, the focus changes, or the inset
  /// leaves no usable space. Invalid padding throws before contacting AX.
  @discardableResult
  static func fillFocusedWindow(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat = 0,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let fill = try Operation.Fill(displays: displays, padding: padding)
    guard processIdentifier > 0, processIdentifier != getpid(), !displays.isEmpty else { return nil }
    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try fill(
        focusedWindow: session.focusedWindow,
        frame: { try session.frame(of: $0) },
        setFrame: { try session.setFrame($0, of: $1) },
      )
    }
  }

  enum FillError: Error, Equatable {
    case invalidPadding
  }
}
