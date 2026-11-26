public extension KeyboardTriggers {
  struct Matcher: Sendable {
    private let rulesBySignature: [Signature: [Rule]]

    public init(rules: [Rule]) {
      rulesBySignature = Dictionary(
        grouping: rules.filter { $0.isGroupEnabled && $0.isWorkflowEnabled },
        by: \.signature,
      )
    }

    /// For each active mode, try app-specific then global bindings. Then try
    /// the same scopes without a mode. The last eligible rule wins a tie.
    public func match(
      _ signature: Signature,
      frontmostBundleIdentifier: String?,
      enabledModeIDs: [String] = [],
    ) -> String? {
      guard let rules = rulesBySignature[signature] else { return nil }

      func matchMode(_ modeID: String?) -> String? {
        var global: String?
        for rule in rules.reversed() {
          guard modeID.map(rule.modeIDs.contains) ?? rule.modeIDs.isEmpty else { continue }
          if let app = frontmostBundleIdentifier {
            guard !rule.disallowedBundleIdentifiers.contains(app) else { continue }
            if rule.allowedBundleIdentifiers.contains(app) { return rule.workflowID }
          }
          if global == nil, rule.allowedBundleIdentifiers.isEmpty { global = rule.workflowID }
        }
        return global
      }

      for modeID in enabledModeIDs {
        if let match = matchMode(modeID) { return match }
      }
      return matchMode(nil)
    }
  }
}
