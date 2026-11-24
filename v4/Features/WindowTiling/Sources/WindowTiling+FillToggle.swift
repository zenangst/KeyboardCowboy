import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

public extension WindowTiling {
  /// Caller-owned history for one window and display geometry. Discard it
  /// after restoring, closing the window, or ending the app session.
  struct FillRestorePoint: Sendable {
    let application: NSRunningApplication
    let id: CGWindowID
    let visibleBounds: CGRect
    let margin: CGFloat
    let tile: Action

    func matches(application: NSRunningApplication, id: CGWindowID, visibleBounds: CGRect, margin: CGFloat) -> Bool {
      self.application.isEqual(application) && self.id == id &&
        self.visibleBounds == visibleBounds && self.margin == margin
    }
  }

  enum FillToggleResult: Sendable {
    case filled(restorePoint: FillRestorePoint?)
    case restored(Action)
  }

  /// Picks native Fill, or restores a matching window that still fills the
  /// supplied usable bounds. Unknown starting layouts yield no restore point.
  /// An already-filled window without matching history is left alone.
  /// Success means the menu pick was accepted, not that the layout settled.
  /// Restoring re-applies the native tile, not its exact previous frame.
  static func toggleFill(
    in pid: pid_t, visibleBounds: CGRect, margin: CGFloat, restoringFrom point: FillRestorePoint? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FillToggleResult? {
    guard pid > 0, pid != getpid(),
          validLayout(visibleBounds, margin: margin),
          let application = NSWorkspace.shared.frontmostApplication,
          application.processIdentifier == pid else { return nil }

    return try await accessibility.withApplication(processIdentifier: pid) { session in
      guard let window = try session.focusedWindow(), let id = try session.windowIDCandidate(for: window),
            let frame = onScreenFrame(id: id, pid: pid), frame.intersects(visibleBounds) else { return nil }

      let current = classify(frame, in: visibleBounds, margin: margin)
      let prior = point.flatMap {
        $0.matches(application: application, id: id, visibleBounds: visibleBounds, margin: margin) ? $0.tile : nil
      }
      guard let action = fillToggleAction(current: current, prior: prior) else { return nil }

      let accepted = try execute(action, in: session) {
        guard let active = NSWorkspace.shared.frontmostApplication, active.isEqual(application),
              try session.focusedWindow() == window else { return false }

        return onScreenFrame(id: id, pid: pid) == frame
      }
      guard accepted else { return nil }

      if action != .fill { return .restored(action) }
      return .filled(restorePoint: current.map {
        FillRestorePoint(application: application, id: id, visibleBounds: visibleBounds, margin: margin, tile: $0)
      })
    }
  }

  internal static func fillToggleAction(current: Action?, prior: Action?) -> Action? {
    current == .fill ? prior : .fill
  }

  internal static func onScreenFrame(id: CGWindowID, pid: pid_t) -> CGRect? {
    let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
    guard let row = rows?.first(where: {
      $0[kCGWindowNumber as String] as? CGWindowID == id && $0[kCGWindowOwnerPID as String] as? pid_t == pid
    }), let bounds = row[kCGWindowBounds as String] as? [String: Any] else { return nil }

    return CGRect(dictionaryRepresentation: bounds as CFDictionary)
  }
}
