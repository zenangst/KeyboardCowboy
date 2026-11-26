import CoreGraphics
import Foundation

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
}
