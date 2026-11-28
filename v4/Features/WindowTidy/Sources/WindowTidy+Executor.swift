import CoreGraphics

public extension WindowTidy {
  @MainActor
  struct Executor {
    public struct Result: Equatable, Sendable {
      public let applied: [CGWindowID]
      public let skipped: [CGWindowID]
      public let restoredFocus: Bool
    }

    private let inventory: @MainActor () -> [Window]
    private let apply: @MainActor (Plan.Step) async throws -> Bool
    private let restore: @MainActor (Window) async throws -> Bool

    /// Effect adapters must verify the exact target immediately before acting,
    /// and return false when unavailable. Group layouts contain individual steps.
    public init(
      inventory: @escaping @MainActor () -> [Window],
      apply: @escaping @MainActor (Plan.Step) async throws -> Bool,
      restore: @escaping @MainActor (Window) async throws -> Bool,
    ) {
      self.inventory = inventory
      self.apply = apply
      self.restore = restore
    }

    public func run(_ request: Request, visibleFrame: CGRect, spacing: CGFloat = 0) async throws -> Result {
      try Task.checkCancellation()
      let plan = WindowTidy.plan(windows: inventory(), visibleFrame: visibleFrame, spacing: spacing, rules: request.rules)
      return try await run(plan, visibleFrame: visibleFrame)
    }

    func run(_ plan: Plan, visibleFrame: CGRect) async throws -> Result {
      var applied: [CGWindowID] = []
      var skipped: [CGWindowID] = []
      for step in plan.steps {
        try Task.checkCancellation()
        guard let fresh = verified(step.window, in: visibleFrame), fresh.frame == step.window.frame else {
          skipped.append(step.window.id)
          continue
        }
        try Task.checkCancellation()
        if try await apply(.init(window: fresh, action: step.action)) {
          applied.append(step.window.id)
        } else {
          skipped.append(step.window.id)
        }
      }

      try Task.checkCancellation()
      let restored: Bool
      if !applied.isEmpty, let original = plan.restoreFocus, let fresh = verified(original, in: visibleFrame) {
        try Task.checkCancellation()
        restored = try await restore(fresh)
      } else {
        restored = false
      }
      try Task.checkCancellation()
      return .init(applied: applied, skipped: skipped, restoredFocus: restored)
    }

    private func verified(_ expected: Window, in visibleFrame: CGRect) -> Window? {
      let matches = inventory().filter { $0.id == expected.id }
      guard matches.count == 1, let fresh = matches.first, fresh.owner == expected.owner,
            fresh.bundleIdentifier == expected.bundleIdentifier, fresh.isEligible else { return nil }
      let overlap = visibleFrame.intersection(fresh.frame)
      return overlap.isNull || overlap.isEmpty ? nil : fresh
    }
  }
}
