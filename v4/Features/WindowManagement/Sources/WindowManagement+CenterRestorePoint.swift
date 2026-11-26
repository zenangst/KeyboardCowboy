import CoreGraphics
import Foundation

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
}
