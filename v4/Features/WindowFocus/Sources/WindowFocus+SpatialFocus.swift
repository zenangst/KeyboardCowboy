#if DEBUG || WINDOW_FOCUS_VALIDATION
import AccessibilitySystem
import CoreGraphics

public extension WindowFocus {
  /// Experimental effect runner. Use a single session across repeated invocations.
  /// Display rectangles use top-left global coordinates, like the selectors.
  @MainActor
  final class SpatialFocus {
    private let operation: Operation.SpatialFocus

    public init(using accessibility: AccessibilitySystem.Client = .init()) {
      operation = .init(accessibility: accessibility)
    }

    /// Returns true only if the selected window was observed focused after the attempt.
    public func center(in display: CGRect, visibleFrame: CGRect, spacing: CGFloat = 0) async throws -> Bool {
      try await operation(.center(display, visibleFrame, spacing))
    }

    /// Repeating a quarter uses the same cycle; there is no separate Focus Behind operation.
    public func quarter(_ quarter: Quarter, in display: CGRect, spacing: CGFloat = 0) async throws -> Bool {
      try await operation(.quarter(quarter, display, spacing))
    }

    /// Call on Space changes or external focus changes.
    public func reset() {
      operation.reset()
    }
  }
}
#endif
