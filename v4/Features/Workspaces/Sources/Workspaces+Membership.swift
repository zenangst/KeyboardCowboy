public extension Workspaces {
  /// Ordered dynamic assignments. The host supplies app and workspace IDs and owns observation.
  struct Membership: Sendable {
    public enum MoveResult: Sendable {
      case added
      case removed
    }

    private var assignments: [String: [String]] = [:]

    public init() {}

    public func bundleIdentifiers(for workspaceID: String) -> [String] {
      assignments[workspaceID] ?? []
    }

    /// Stage Manager replaces the entire list. Otherwise, prepend even repeated assignments.
    public mutating func assign(_ bundleIdentifier: String, to workspaceID: String, stageManagerEnabled: Bool) {
      if stageManagerEnabled {
        assignments[workspaceID] = [bundleIdentifier]
      } else {
        assignments[workspaceID, default: []].insert(bundleIdentifier, at: 0)
      }
    }

    /// Remove all existing occurrences. Add to the target only if it wasn't already a member there.
    public mutating func moveOrRemove(
      _ bundleIdentifier: String, to workspaceID: String, stageManagerEnabled: Bool,
    ) -> MoveResult {
      let wasMember = bundleIdentifiers(for: workspaceID).contains(bundleIdentifier)
      retain { $0 != bundleIdentifier }
      if wasMember { return .removed }

      assign(bundleIdentifier, to: workspaceID, stageManagerEnabled: stageManagerEnabled)
      return .added
    }

    /// Supply a complete snapshot of live bundle IDs, excluding terminated processes.
    public mutating func prune(runningBundleIdentifiers: Set<String>) {
      retain(runningBundleIdentifiers.contains)
    }

    /// Move the first matching assignment to the end of the current workspace only.
    public mutating func recordFocus(_ bundleIdentifier: String, in workspaceID: String) {
      guard var members = assignments[workspaceID], let index = members.firstIndex(of: bundleIdentifier) else { return }
      members.append(members.remove(at: index))
      assignments[workspaceID] = members
    }

    private mutating func retain(_ predicate: (String) -> Bool) {
      assignments = assignments.compactMapValues { members in
        let retained = members.filter(predicate)
        return retained.isEmpty ? nil : retained
      }
    }
  }
}
