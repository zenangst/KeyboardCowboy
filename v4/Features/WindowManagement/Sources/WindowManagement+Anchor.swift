import AccessibilitySystem
import AppKit
import CoreGraphics

public extension WindowManagement {
  enum AnchorError: Error, Equatable {
    case invalidPadding
    case invalidMinimumSize
  }

  enum AnchorMode: Sendable {
    case nearest
    /// Advances an already anchored frame to the next size, wrapping from
    /// two-thirds to one-third. Otherwise snaps to the nearest size.
    case cycle
  }

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

  /// Snaps the active app's focused window to an edge or corner of the
  /// most-overlapped display's padded usable area. Picks the nearest of
  /// one-third, one-half and two-thirds by width (height for top/bottom).
  /// Cardinal anchors span the other axis. The app may clamp the requested
  /// frame; the observed frame reports the result. Pass `.cycle` on repeats
  /// to advance only when the full frame still matches an anchor band.
  /// Supply a known `minimumSize` to fit each band to that minimum before
  /// positioning it. If the minimum cannot fit inside the padded area,
  /// returns nil without writing. No minimum-size probe is performed.
  @discardableResult
  static func anchorFocusedWindow(
    in processIdentifier: pid_t, direction: Direction, displays: [Display], padding: CGFloat = 0, mode: AnchorMode = .nearest,
    minimumSize: CGSize? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let anchor = try Operation.Anchor(direction: direction, displays: displays, padding: padding, mode: mode, minimumSize: minimumSize)
    return try await placeFocusedWindow(in: processIdentifier, using: accessibility, requestedFrame: anchor.requestedFrame)
  }

  /// Anchors the window and returns a point for the next repeat. A matching
  /// point lets the cycle advance from the requested band even if the app
  /// clamped the resulting frame. A stale point falls back to normal cycling;
  /// omitting the point starts with a nearest-band snap.
  static func anchorFocusedWindowCycling(
    in processIdentifier: pid_t, direction: Direction, displays: [Display], padding: CGFloat = 0,
    minimumSize: CGSize? = nil, continuingFrom point: AnchorCyclePoint? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> (frame: FrameResult, cyclePoint: AnchorCyclePoint?)? {
    let pid = processIdentifier
    let anchor = try Operation.Anchor(direction: direction, displays: displays, padding: padding,
                                      mode: point == nil ? .nearest : .cycle, minimumSize: minimumSize)
    let launchDate = NSRunningApplication(processIdentifier: pid)?.launchDate
    guard let result = try await placeIdentifiedFocusedWindow(in: pid, using: accessibility, request: { id, original, onScreen in
      let previous = point?.band(in: pid, launchDate: launchDate, id: id, direction: direction,
                                 current: original, onScreen: onScreen)
      return anchor.requestedFrame(for: original, continuingFrom: previous).map(PlacementRequest.place)
    }) else { return nil }
    guard let launchDate, NSRunningApplication(processIdentifier: pid)?.launchDate == launchDate else {
      return (result.frame, nil)
    }

    return (result.frame, AnchorCyclePoint(pid: pid, launchDate: launchDate, id: result.id, direction: direction,
                                           requested: result.frame.requested, observed: result.frame.observed))
  }
}
