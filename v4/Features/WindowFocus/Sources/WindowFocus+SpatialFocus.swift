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

    /// Restricts both the anchor and targets to this process.
    public convenience init(in processIdentifier: pid_t, using accessibility: AccessibilitySystem.Client = .init()) {
      self.init(in: [processIdentifier], using: accessibility)
    }

    /// Restricts both the anchor and targets to the supplied processes.
    public init(in processIdentifiers: Set<pid_t>, using accessibility: AccessibilitySystem.Client = .init()) {
      operation = .init(accessibility: accessibility, processIdentifiers: processIdentifiers)
    }

    /// Returns true only if the selected window was observed focused after the attempt.
    public func center(in display: CGRect, visibleFrame: CGRect, spacing: CGFloat = 0) async throws -> Bool {
      try await operation(.center(display, visibleFrame, spacing))
    }

    /// Repeating a quarter uses the same cycle; there is no separate Focus Behind operation.
    public func quarter(_ quarter: Quarter, in display: CGRect, spacing: CGFloat = 0) async throws -> Bool {
      try await operation(.quarter(quarter, display, spacing))
    }

    /// Uses the verified focused window as the anchor. If provided, `tiling`
    /// describes the anchor on the display containing the initial probe.
    public func directional(
      _ direction: DirectionalSearch.Direction,
      visibleFrames: [CGRect],
      tiling: DirectionalSearch.Tiling? = nil,
      spacing: CGFloat = 0,
      mainDisplayFrame: CGRect? = nil,
      deadzoneSpacing: CGFloat? = nil,
    ) async throws -> Bool {
      try await operation(.directional(.init(direction: direction, visibleFrames: visibleFrames, tiling: tiling,
                                              spacing: spacing, mainDisplayFrame: mainDisplayFrame,
                                              deadzoneSpacing: deadzoneSpacing)))
    }

    /// Steps through visible windows on the current Space. Use the same session
    /// for successive calls so Previous can prefer confirmed focus history.
    public func cycleInCurrentSpace(_ direction: SpaceRing.Direction) async throws -> Bool {
      try await operation(.spaceRing(direction))
    }

    /// Call on Space changes or when discarding focus history.
    public func reset() {
      operation.reset()
    }
  }
}
#endif
