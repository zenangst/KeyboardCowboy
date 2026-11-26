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
    ) -> SequenceMatch {
      guard let first = signatures.first, let rules = rulesBySignature[first] else { return .noMatch }
      let suffix = signatures.dropFirst()
      func usesWildcard(_ rule: Rule) -> Bool {
        rule.endsWithAnyKey && suffix.count == rule.continuation.count + 1
      }
      guard let rule = Self.winner(in: rules, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                   enabledModeIDs: enabledModeIDs, isFallback: usesWildcard,
                                   accepting: {
                                     usesWildcard($0) ? $0.continuation.elementsEqual(suffix.dropLast())
                                       : $0.continuation.starts(with: suffix)
                                   }) else { return .noMatch }
      let length = rule.continuation.count + (rule.endsWithAnyKey ? 1 : 0)
      return length == suffix.count ? .exact(rule.workflowID) : .partial
    }

    private static func winner(
      in rules: [Rule], frontmostBundleIdentifier: String?, enabledModeIDs: [String],
      isFallback: (Rule) -> Bool = { _ in false },
      accepting: (Rule) -> Bool,
    ) -> Rule? {
      func matchMode(_ modeID: String?) -> Rule? {
        var global: Rule?
        var scopedFallback: Rule?
        for rule in rules.reversed() {
          guard modeID.map(rule.modeIDs.contains) ?? rule.modeIDs.isEmpty, accepting(rule) else { continue }
          if let app = frontmostBundleIdentifier {
            guard !rule.disallowedBundleIdentifiers.contains(app) else { continue }
            if rule.allowedBundleIdentifiers.contains(app) {
              if !isFallback(rule) { return rule }
              if scopedFallback == nil { scopedFallback = rule }
              continue
            }
          }
          if rule.allowedBundleIdentifiers.isEmpty,
             global.map({ isFallback($0) && !isFallback(rule) }) ?? true { global = rule }
        }
        return scopedFallback ?? global
      }

      for modeID in enabledModeIDs {
        if let match = matchMode(modeID) { return match }
      }
      return matchMode(nil)
    }
  }
}
