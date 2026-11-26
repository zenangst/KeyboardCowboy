public enum ApplicationTriggers {
  public static let anyApplication = "*.*.*"

  /// Matches observed changes only. Rule order is preserved within each event and target,
  /// including repeated workflow IDs from separate matching rules.
  public static func match(
    _ transition: Transition,
    rules: [Rule],
    enabledModeIDs: Set<String> = [],
  ) -> [Match] {
    let eligible = rules.filter {
      $0.isGroupEnabled && $0.isWorkflowEnabled && $0.requiredModeIDs.isSubset(of: enabledModeIDs)
    }
    var matches: [Match] = []

    func append(_ context: Context, for bundleIdentifier: String, matching target: String) {
      for rule in eligible where rule.bundleIdentifier == target && rule.contexts.contains(context) {
        matches.append(Match(workflowID: rule.workflowID, bundleIdentifier: bundleIdentifier, context: context))
      }
    }

    switch transition {
    case let .runningApplications(previous, current):
      // Match first launch and last exit by bundle, not each instance or a list reorder.
      // Preserve v3's removal-before-insertion ordering for distinct bundles.
      var remaining = Set(current)
      for bundleIdentifier in previous.reversed() where remaining.insert(bundleIdentifier).inserted {
        append(.closed, for: bundleIdentifier, matching: bundleIdentifier)
      }
      var existing = Set(previous)
      for bundleIdentifier in current where existing.insert(bundleIdentifier).inserted {
        append(.launched, for: bundleIdentifier, matching: bundleIdentifier)
      }
    case let .frontmostApplication(previous, current):
      guard previous != current else { return [] }
      if let current {
        append(.frontMost, for: current, matching: anyApplication)
        append(.frontMost, for: current, matching: current)
      }
      if let previous {
        append(.resignFrontMost, for: previous, matching: previous)
      }
    }
    return matches
  }
}
