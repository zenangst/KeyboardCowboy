import AccessibilitySystem
import CoreGraphics
import Darwin

public extension WindowManagement {
  enum MoveConstraint: Sendable {
    case unconstrained
    /// Clamp to the visible area of the display with the most window overlap.
    case visibleArea(displays: [Display], padding: CGFloat = 0)
  }

  enum MoveError: Error, Equatable {
    case invalidDistance, invalidPadding
  }

  /// Moves the specified application's focused window without resizing it.
  /// Distance is in points per axis; top and leading decrease AX y and x.
  @discardableResult
  static func moveFocusedWindow(
    in processIdentifier: pid_t, direction: Direction, distance: CGFloat,
    constraint: MoveConstraint = .unconstrained,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let operation = try Operation.Move(direction: direction, distance: distance, constraint: constraint)
    guard processIdentifier > 0, processIdentifier != getpid() else { return nil }

    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try Operation.moveFocusedWindow(
        focusedWindow: session.focusedWindow,
        frame: { try session.frame(of: $0) },
        requested: operation.requestedFrame,
        move: { try session.write(.position, value: $0, to: $1) },
      )
    }
  }
}
