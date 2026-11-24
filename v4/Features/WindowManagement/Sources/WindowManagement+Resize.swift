import AccessibilitySystem
import CoreGraphics

public extension WindowManagement {
  enum ResizeChange: Sendable {
    case grow, shrink
  }

  enum ResizeConstraint: Sendable {
    case unconstrained
    case visibleArea(displays: [Display], padding: CGFloat = 0)
  }

  enum ResizeError: Error, Equatable {
    case invalidDistance, invalidPadding
  }

  /// Resizes the specified edges of the active app's focused window by points
  /// per axis. The requested frame preserves the opposite edges; the observed
  /// frame can differ if the app enforces size limits. A constrained resize
  /// requires the existing window to fit inside the selected padded area.
  @discardableResult
  static func resizeFocusedWindow(
    in processIdentifier: pid_t, change: ResizeChange, direction: Direction, distance: CGFloat,
    constraint: ResizeConstraint = .unconstrained,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let operation = try Operation.Resize(change: change, direction: direction, distance: distance, constraint: constraint)
    return try await placeFocusedWindow(in: processIdentifier, using: accessibility, requestedFrame: operation.requestedFrame)
  }
}
