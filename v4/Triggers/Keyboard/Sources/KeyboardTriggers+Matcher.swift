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
                  enabledModeIDs: enabledModeIDs) { $0.continuation.isEmpty && !$0.endsWithAnyKey }?.workflowID
    }

    func matchSequence(
      _ signatures: [Signature], frontmostBundleIdentifier: String?, enabledModeIDs: [String],
    ) -> (decision: Decision, rule: Rule?) {
      guard let first = signatures.first, let rules = rulesBySignature[first] else { return (.noMatch, nil) }

      let suffix = signatures.dropFirst()
      func usesWildcard(_ rule: Rule) -> Bool {
        rule.endsWithAnyKey && suffix.count == rule.continuation.count + 1
      }
      func isPartial(_ rule: Rule) -> Bool {
        suffix.count < rule.continuation.count + (rule.endsWithAnyKey ? 1 : 0)
      }
      guard let rule = Self.winner(in: rules, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                   enabledModeIDs: enabledModeIDs, isFallback: usesWildcard,
                                   isPartial: isPartial,
                                   accepting: {
                                     usesWildcard($0) ? $0.continuation.elementsEqual(suffix.dropLast())
                                       : $0.continuation.starts(with: suffix)
                                   }) else { return (.noMatch, nil) }

      let decision = Decision(match: isPartial(rule) ? .partial : .exact(rule.workflowID),
                              disposition: rule.passthrough ? .passThrough : .suppress)
      return (decision, rule)
    }

    private static func winner(
      in rules: [Rule], frontmostBundleIdentifier: String?, enabledModeIDs: [String],
      isFallback: (Rule) -> Bool = { _ in false },
      isPartial: (Rule) -> Bool = { _ in false },
      accepting: (Rule) -> Bool,
    ) -> Rule? {
      func shouldReplace(_ current: Rule?, with candidate: Rule) -> Bool {
        guard let current else { return true }

        if isFallback(current) != isFallback(candidate) { return !isFallback(candidate) }
        // v3's cache keeps an existing leader partial against later partials,
        // but a later exact binding can still replace it.
        return !(current.leaderKey && isPartial(current) && isPartial(candidate))
      }

      func matchMode(_ modeID: String?) -> Rule? {
        var global: Rule?
        var scoped: Rule?
        for rule in rules {
          guard modeID.map(rule.modeIDs.contains) ?? rule.modeIDs.isEmpty, accepting(rule) else { continue }

          if let app = frontmostBundleIdentifier {
            guard !rule.disallowedBundleIdentifiers.contains(app) else { continue }

            if app != Rule.globalBundleIdentifier, rule.allowedBundleIdentifiers.contains(app) {
              if shouldReplace(scoped, with: rule) { scoped = rule }
              continue
            }
          }

          if (rule.allowedBundleIdentifiers.isEmpty ||
            rule.allowedBundleIdentifiers.contains(Rule.globalBundleIdentifier)),
            shouldReplace(global, with: rule) {
            global = rule
          }
        }
        return scoped ?? global
      }

      for modeID in enabledModeIDs {
        if let match = matchMode(modeID) { return match }
      }
      return matchMode(nil)
    }
  }
}
