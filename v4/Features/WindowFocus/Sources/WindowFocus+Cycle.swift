#if DEBUG || WINDOW_FOCUS_VALIDATION
import AccessibilitySystem
import CoreGraphics

/// Active-application window focus commands.
public enum WindowFocus {
  /// A host-provided focus transition for the active app. Discard it when
  /// the app instance changes; the executor does not observe or store history.
  public struct History: Sendable {
    let processIdentifier: pid_t
    let current: CGWindowID
    let previous: CGWindowID

    public init(processIdentifier: pid_t, current: CGWindowID, previous: CGWindowID) {
      self.processIdentifier = processIdentifier
      self.current = current
      self.previous = previous
    }
  }

  /// Cycles within the active app in ascending CG ID order, independent of
  /// Z-order changes after a raise. No IDs are retained between calls.
  @discardableResult
  public static func nextWindow(
    in processIdentifier: pid_t,
    using accessibility: AccessibilitySystem.Client = .init(),
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    let cycle = Operation.Cycle(accessibility: accessibility)
    return try await cycle(.next, in: processIdentifier, isAppActive: isAppActive)
  }

  /// Prefers the last focused eligible window, otherwise cycles backward.
  @discardableResult
  public static func previousWindow(
    in processIdentifier: pid_t,
    history: History? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    let cycle = Operation.Cycle(accessibility: accessibility)
    return try await cycle(.previous(history), in: processIdentifier, isAppActive: isAppActive)
  }
}
#endif
