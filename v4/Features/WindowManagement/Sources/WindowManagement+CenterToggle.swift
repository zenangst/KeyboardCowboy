import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

public extension WindowManagement {
  /// A caller-owned, in-memory point for the current window and app session.
  /// Discard it after restoring or when the window closes.
  struct CenterRestorePoint: Sendable {
    let pid: pid_t
    let launchDate: Date
    let id: CGWindowID
    let original: CGRect
    let centered: CGRect
  }

  enum CenterToggleResult: Sendable {
    case centered(frame: FrameResult, restorePoint: CenterRestorePoint?)
    case restored(FrameResult)
  }

  /// Centers or restores the active app's verified focused window, writing
  /// only its position. Pass the returned point to toggle back. A stale or
  /// unrelated point centers instead. Returns nil when the focused window
  /// cannot be verified or AX and Core Graphics disagree about its frame.
  static func toggleFocusedWindowCenter(
    in processIdentifier: pid_t, displays: [Display], restoringFrom point: CenterRestorePoint? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CenterToggleResult? {
    let pid = processIdentifier
    guard pid > 0, pid != getpid(), !displays.isEmpty,
          NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return nil }
    let center = Operation.Center(displays: displays)
    return try await accessibility.withApplication(processIdentifier: pid) { session in
      guard let window = try session.focusedWindow(),
            let id = try session.windowIDCandidate(for: window) else { return nil }
      let launchDate = NSRunningApplication(processIdentifier: pid)?.launchDate
      let original = try session.frame(of: window)
      guard let onScreen = compositorFrame(id: id, owner: pid),
            let placement = center.togglePlacement(
              in: pid, launchDate: launchDate, id: id, current: original, onScreen: onScreen, point: point,
            ),
            try session.focusedWindow() == window,
            NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return nil }
      let requested = placement.frame
      var observed = original
      if !Operation.FrameSettling.matchesOrigin(original, requested.origin) {
        try session.write(.position, value: requested.origin, to: window)
        observed = try session.frame(of: window)
      }
      let result = FrameResult(original: original, requested: requested, observed: observed)
      if case .restore = placement { return .restored(result) }
      guard let launchDate, !Operation.FrameSettling.matchesOrigin(observed, original.origin),
            observed.size == original.size,
            NSRunningApplication(processIdentifier: pid)?.launchDate == launchDate else {
        return .centered(frame: result, restorePoint: nil)
      }
      return .centered(frame: result, restorePoint: .init(
        pid: pid, launchDate: launchDate, id: id, original: original, centered: observed,
      ))
    }
  }
}
