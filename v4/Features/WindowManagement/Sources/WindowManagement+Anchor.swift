import AccessibilitySystem
import CoreGraphics

public extension WindowManagement {
  enum AnchorError: Error, Equatable {
    case invalidPadding
  }

  /// Snaps the active app's focused window to an edge or corner of the
  /// most-overlapped display's padded usable area. Picks the nearest of
  /// one-third, one-half and two-thirds by width (height for top/bottom).
  /// Cardinal anchors span the other axis. The app may clamp the requested
  /// frame; the observed frame reports the result. Repeats do not cycle.
  @discardableResult
  static func anchorFocusedWindow(
    in processIdentifier: pid_t, direction: Direction, displays: [Display], padding: CGFloat = 0,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let anchor = try Operation.Anchor(direction: direction, displays: displays, padding: padding)
    return try await placeFocusedWindow(in: processIdentifier, using: accessibility, requestedFrame: anchor.requestedFrame)
  }
}
