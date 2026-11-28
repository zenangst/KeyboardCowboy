import AccessibilitySystem
import Darwin

public extension WindowFocus {
  /// Cycles within the active app in ascending CG ID order, independent of
  /// Z-order changes after a raise. No IDs are retained between calls.
  /// Returns true only when the exact on-screen target is observed focused.
  @discardableResult
  static func nextWindow(
    in processIdentifier: pid_t,
    using accessibility: AccessibilitySystem.Client = .init(),
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    let cycle = Operation.Cycle(accessibility: accessibility)
    return try await cycle(.next, in: processIdentifier, isAppActive: isAppActive)
  }

  /// Prefers the last focused eligible window, otherwise cycles backward.
  /// Returns true only when the exact on-screen target is observed focused.
  @discardableResult
  static func previousWindow(
    in processIdentifier: pid_t,
    history: History? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    let cycle = Operation.Cycle(accessibility: accessibility)
    return try await cycle(.previous(history), in: processIdentifier, isAppActive: isAppActive)
  }
}
