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
      Self.winner(in: rulesBySignature[signature] ?? [], frontmostBundleIdentifier: frontmostBundleIdentifier,
                  enabledModeIDs: enabledModeIDs) { $0.continuation.isEmpty }?.workflowID
    }

    func matchSequence(
      _ signatures: [Signature], frontmostBundleIdentifier: String?, enabledModeIDs: [String],
    ) -> SequenceMatch {
      guard let first = signatures.first, let rules = rulesBySignature[first] else { return .noMatch }
      let suffix = signatures.dropFirst()
      guard let rule = Self.winner(in: rules, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                   enabledModeIDs: enabledModeIDs,
                                   accepting: { $0.continuation.starts(with: suffix) }) else { return .noMatch }
      return rule.continuation.count == suffix.count ? .exact(rule.workflowID) : .partial
    }

    private static func winner(
      in rules: [Rule], frontmostBundleIdentifier: String?, enabledModeIDs: [String],
      accepting: (Rule) -> Bool,
    ) -> Rule? {
      func matchMode(_ modeID: String?) -> Rule? {
        var global: Rule?
        for rule in rules.reversed() {
          guard modeID.map(rule.modeIDs.contains) ?? rule.modeIDs.isEmpty, accepting(rule) else { continue }
          if let app = frontmostBundleIdentifier {
            guard !rule.disallowedBundleIdentifiers.contains(app) else { continue }
            if rule.allowedBundleIdentifiers.contains(app) { return rule }
          }
          if global == nil, rule.allowedBundleIdentifiers.isEmpty { global = rule }
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
