import CoreGraphics
import Foundation

public extension WindowManagement {
  /// A caller-owned continuation for one window in its current app session.
  /// Discard it when the window closes or the anchor sequence ends.
  struct AnchorCyclePoint: Sendable {
    let pid: pid_t
    let launchDate: Date
    let id: CGWindowID
    let direction: Direction
    let requested: CGRect
    let observed: CGRect

    func band(in pid: pid_t, launchDate: Date?, id: CGWindowID, direction: Direction,
              current: CGRect, onScreen: CGRect) -> CGRect? {
      let settling = Operation.FrameSettling(origin: observed.origin, size: observed.size)
      guard self.pid == pid, self.launchDate == launchDate, self.id == id, self.direction == direction,
            settling.matches(current), settling.matches(onScreen) else { return nil }

      return requested
    }
  }
}
