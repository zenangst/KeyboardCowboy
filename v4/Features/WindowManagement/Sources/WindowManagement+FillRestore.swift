import AccessibilitySystem
import AppKit
import CoreGraphics

public extension WindowManagement {
  /// An in-memory snapshot for one filled window. Keep it only for the current
  /// app session and discard it after restoring or when the window closes.
  struct FillRestorePoint: Sendable {
    let pid: pid_t
    let launchDate: Date
    let id: CGWindowID
    let original: CGRect
    let filled: CGRect

    func target(id: CGWindowID, current: CGRect, onScreen: CGRect, displays: [Display]) -> CGRect? {
      guard id == self.id, current == filled,
            Operation.FrameSettling.matchesOrigin(onScreen, filled.origin),
            abs(onScreen.width - filled.width) <= 1, abs(onScreen.height - filled.height) <= 1,
            WindowManagement.displayIndex(for: original, on: displays) != nil else { return nil }
      return original
    }
  }

  /// Fills the focused window and returns an optional restore point. A no-op
  /// Fill or an unavailable process launch date yields no restore point.
  static func fillFocusedWindowRecordingRestore(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat = 0,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> (frame: FrameResult, restorePoint: FillRestorePoint?)? {
    let launchDate = NSRunningApplication(processIdentifier: processIdentifier)?.launchDate
    guard let result = try await fillIdentifiedFocusedWindow(
      in: processIdentifier, displays: displays, padding: padding, using: accessibility,
    ) else { return nil }
    let frame = result.frame
    guard let launchDate, frame.original != frame.observed,
          NSRunningApplication(processIdentifier: processIdentifier)?.launchDate == launchDate else { return (frame, nil) }
    return (frame, FillRestorePoint(pid: processIdentifier, launchDate: launchDate, id: result.id,
                                    original: frame.original, filled: frame.observed))
  }

  /// Restores only the same active, focused window while it still matches the
  /// recorded Fill result and its saved frame overlaps a usable display.
  /// The observed frame may differ if the app or window server clamps the
  /// request. An already completed move or shrink is not rolled back.
  @discardableResult
  static func restoreFocusedWindow(
    from point: FillRestorePoint, displays: [Display],
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    try await placeIdentifiedFocusedWindow(in: point.pid, using: accessibility, shrinkBeforeMoving: true) { id, original, onScreen in
      guard NSRunningApplication(processIdentifier: point.pid)?.launchDate == point.launchDate else { return nil }
      return point.target(id: id, current: original, onScreen: onScreen, displays: displays)
    }?.frame
  }
}
