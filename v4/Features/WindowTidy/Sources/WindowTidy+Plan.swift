import CoreGraphics
import WindowTilingFeature

public extension WindowTidy {
  struct Rule: Codable, Hashable, Sendable {
    public let bundleIdentifier: String
    public let tiling: WindowTiling.Action

    public init(bundleIdentifier: String, tiling: WindowTiling.Action) {
      self.bundleIdentifier = bundleIdentifier
      self.tiling = tiling
    }
  }

  struct Plan: Equatable, Sendable {
    public struct Step: Equatable, Sendable {
      public let window: Window
      public let action: WindowTiling.Action
    }

    /// Target order is back-to-front when operating on individual windows.
    public let steps: [Step]
    /// Restore this original window after applying the plan, if it is still eligible.
    public let restoreFocus: Window?
  }

  /// Both window and display frames use top-left global coordinates. The
  /// inventory is front-to-back; this planner performs no window effects.
  static func plan(
    windows: [Window], visibleFrame: CGRect, spacing: CGFloat = 0, rules: [Rule] = [],
  ) -> Plan {
    guard valid(visibleFrame), spacing.isFinite, spacing >= 0,
          spacing < min(visibleFrame.width, visibleFrame.height) / 2 else { return .init(steps: [], restoreFocus: nil) }
    let counts = Dictionary(grouping: windows, by: \.id)
    let eligible = windows.filter {
      let overlap = visibleFrame.intersection($0.frame)
      return counts[$0.id]?.count == 1 && $0.isEligible && !overlap.isNull && !overlap.isEmpty
    }
    guard let current = eligible.first else { return .init(steps: [], restoreFocus: nil) }
    let layout: (Window) -> WindowTiling.Action? = {
      WindowTiling.classify($0.frame, in: visibleFrame, margin: spacing, tolerance: max(1, spacing))
    }
    let assignments = Set(eligible.map(\.owner)).count == 1
      ? singleApp(eligible, anchor: current, layout: layout)
      : multipleApps(eligible, anchor: current, rules: rules, layout: layout)
    let steps = assignments.filter { $0.action != layout($0.window) }
    return .init(steps: steps, restoreFocus: steps.isEmpty ? nil : current)
  }

  static func valid(_ frame: CGRect) -> Bool {
    !frame.isInfinite && !frame.isNull && frame.size.width > 0 && frame.size.height > 0
      && [frame.minX, frame.minY, frame.maxX, frame.maxY].allSatisfy(\.isFinite)
  }
}
