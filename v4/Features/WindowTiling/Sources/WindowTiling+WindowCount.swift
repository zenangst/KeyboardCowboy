import AccessibilitySystem
import Darwin

public extension WindowTiling {
  enum ArrangementSide: Sendable {
    case left, right
  }

  /// Resolves the native action for the caller's eligible window count.
  /// Dynamic arrangements need a classified side when two or more windows
  /// are available. A nonpositive count produces no action.
  static func resolvedAction(
    _ action: Action, eligibleWindowCount count: Int, dynamicSide: ArrangementSide? = nil,
  ) -> Action? {
    guard count > 0 else { return nil }

    switch action {
    case .arrangeLeftRight, .arrangeRightLeft, .arrangeTopBottom, .arrangeBottomTop:
      return count == 1 ? .fill : action
    case .arrangeLeftQuarters, .arrangeRightQuarters, .arrangeTopQuarters, .arrangeBottomQuarters:
      if count == 1 { return .fill }
      guard count == 2 else { return action }

      switch action {
      case .arrangeLeftQuarters: return .arrangeLeftRight
      case .arrangeRightQuarters: return .arrangeRightLeft
      case .arrangeTopQuarters: return .arrangeTopBottom
      default: return .arrangeBottomTop
      }
    case .arrangeQuarters:
      switch count {
      case 1: return .fill
      case 2: return .arrangeLeftRight
      case 3: return .arrangeLeftQuarters
      default: return .arrangeQuarters
      }
    case .arrangeDynamicQuarters:
      if count == 1 { return .fill }
      guard let dynamicSide else { return nil }

      switch dynamicSide {
      case .left: return count == 2 ? .arrangeLeftRight : .arrangeLeftQuarters
      case .right: return count == 2 ? .arrangeRightLeft : .arrangeRightQuarters
      }
    default:
      return action
    }
  }

  /// Executes the count-adjusted action. The caller supplies a fresh count
  /// for the target layout; macOS still selects the participating windows.
  @discardableResult
  static func execute(
    _ action: Action, in processIdentifier: pid_t, eligibleWindowCount: Int,
    dynamicSide: ArrangementSide? = nil, using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Bool {
    guard let resolved = resolvedAction(action, eligibleWindowCount: eligibleWindowCount, dynamicSide: dynamicSide) else {
      return false
    }

    return try await execute(resolved, in: processIdentifier, using: accessibility)
  }
}
