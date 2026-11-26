import AppKit
import CoreGraphics

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
}
