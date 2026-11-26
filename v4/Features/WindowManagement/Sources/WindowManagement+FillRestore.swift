import AccessibilitySystem
import AppKit
import CoreGraphics

public extension WindowManagement {
  enum FillToggleResult: Sendable {
    case filled(frame: FrameResult, restorePoint: FillRestorePoint?)
    case restored(FrameResult)
  }

  /// Restores from a matching point, or fills the verified focused window
  /// and returns a new point. Pass the new point on the next invocation.
  /// Points for another window or a changed frame don't trigger a restore.
  /// Returns nil if placement cannot be verified. A partial write is not
  /// rolled back or followed by a second placement attempt.
  static func toggleFocusedWindowFill(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat = 0,
    restoringFrom point: FillRestorePoint? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FillToggleResult? {
    let launchDate = NSRunningApplication(processIdentifier: processIdentifier)?.launchDate
    guard let result = try await fillIdentifiedFocusedWindow(
      in: processIdentifier, displays: displays, padding: padding, using: accessibility, restoringFrom: point,
    ) else { return nil }

    if case .restore = result.request { return .restored(result.frame) }
    return .filled(frame: result.frame, restorePoint: makeFillRestorePoint(
      pid: processIdentifier, launchDate: launchDate, id: result.id, frame: result.frame,
    ))
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

    return (result.frame, makeFillRestorePoint(pid: processIdentifier, launchDate: launchDate, id: result.id, frame: result.frame))
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
    try await placeIdentifiedFocusedWindow(in: point.pid, using: accessibility) { id, original, onScreen in
      guard NSRunningApplication(processIdentifier: point.pid)?.launchDate == point.launchDate else { return nil }

      return point.target(id: id, current: original, onScreen: onScreen, displays: displays).map(PlacementRequest.restore)
    }?.frame
  }

  private static func makeFillRestorePoint(
    pid: pid_t, launchDate: Date?, id: CGWindowID, frame: FrameResult,
  ) -> FillRestorePoint? {
    guard let launchDate, frame.original != frame.observed,
          NSRunningApplication(processIdentifier: pid)?.launchDate == launchDate else { return nil }

    return FillRestorePoint(pid: pid, launchDate: launchDate, id: id, original: frame.original, filled: frame.observed)
  }
}
