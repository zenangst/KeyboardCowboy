import AccessibilitySystem
import CoreGraphics
import Foundation

public extension WindowManagement {
  /// State for one serialized stream of Anchor invocations. The host decides
  /// what counts as a repeat and resets the session when the sequence ends.
  struct AnchorRepeatSession: Sendable {
    struct Invocation: Equatable, Sendable {
      let commandID: UUID
      let pid: pid_t
      let direction: Direction
      let padding: CGFloat
      let minimumSize: CGSize?
    }

    private var last: (invocation: Invocation, point: AnchorCyclePoint)?

    public init() {}

    public mutating func reset() {
      last = nil
    }

    /// Continues only a matching previous invocation. A failure or no result
    /// clears the sequence; a fresh invocation starts at the nearest band.
    @discardableResult
    public mutating func anchor(
      commandID: UUID, isRepeat: Bool, in processIdentifier: pid_t, direction: Direction,
      displays: [Display], padding: CGFloat = 0, minimumSize: CGSize? = nil,
      using accessibility: AccessibilitySystem.Client = .init(),
    ) async throws -> FrameResult? {
      let invocation = Invocation(commandID: commandID, pid: processIdentifier, direction: direction,
                                  padding: padding, minimumSize: minimumSize)
      let point = takePoint(for: invocation, isRepeat: isRepeat)
      try Task.checkCancellation()
      guard let result = try await WindowManagement.anchorFocusedWindowCycling(
        in: processIdentifier, direction: direction, displays: displays, padding: padding,
        minimumSize: minimumSize, continuingFrom: point, using: accessibility,
      ) else { return nil }
      try Task.checkCancellation()
      record(result.cyclePoint, for: invocation)
      return result.frame
    }

    mutating func takePoint(for invocation: Invocation, isRepeat: Bool) -> AnchorCyclePoint? {
      defer { reset() }
      guard isRepeat, let last, last.invocation == invocation else { return nil }
      return last.point
    }

    mutating func record(_ point: AnchorCyclePoint?, for invocation: Invocation) {
      last = point.map { (invocation, $0) }
    }
  }
}
