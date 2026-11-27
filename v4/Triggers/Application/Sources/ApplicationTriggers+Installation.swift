import Combine

public extension ApplicationTriggers {
  /// The caller retains the handle, supplies configuration changes, and forwards matches.
  /// No observation starts until at least one enabled rule has a lifecycle context.
  @MainActor
  static func install(
    rules: [Rule],
    source: Source = .workspace(),
    enabledModeIDs: @escaping @MainActor () -> Set<String> = { [] },
    onMatches: @escaping @MainActor ([Match]) -> Void,
  ) -> Installation {
    let installation = Installation(source: source, enabledModeIDs: enabledModeIDs, onMatches: onMatches)
    installation.update(rules: rules)
    return installation
  }

  @MainActor
  final class Installation {
    private let source: Source
    private let enabledModeIDs: @MainActor () -> Set<String>
    private let onMatches: @MainActor ([Match]) -> Void
    private var rules: [Rule] = []
    private var baseline: Snapshot?
    private var observation: AnyCancellable?
    private var generation: UInt64 = 0

    fileprivate init(
      source: Source,
      enabledModeIDs: @escaping @MainActor () -> Set<String>,
      onMatches: @escaping @MainActor ([Match]) -> Void,
    ) {
      self.source = source
      self.enabledModeIDs = enabledModeIDs
      self.onMatches = onMatches
    }

    /// Changing rules does not restart a live subscription. Modes only affect matching.
    public func update(rules: [Rule]) {
      self.rules = rules.filter { $0.isGroupEnabled && $0.isWorkflowEnabled && !$0.contexts.isEmpty }
      guard !self.rules.isEmpty else { stop(); return }
      guard baseline == nil else { return }

      baseline = source.snapshot()
      let generation = self.generation
      let observation = source.observe { [weak self] change in
        guard let self, self.generation == generation else { return }

        self.receive(change)
      }
      if self.generation == generation {
        self.observation = observation
      } else {
        observation.cancel()
      }
    }

    /// A later update with enabled rules starts a new subscription and seeds a fresh baseline.
    public func stop() {
      generation &+= 1
      baseline = nil
      rules = []
      let observation = self.observation
      self.observation = nil
      observation?.cancel()
    }

    private func receive(_ change: Change) {
      guard var baseline else { return }

      let transition: Transition
      switch change {
      case .runningApplications(let current):
        transition = .runningApplications(previous: baseline.runningBundleIdentifiers, current: current)
        baseline.runningBundleIdentifiers = current
      case .frontmostApplication(let current):
        transition = .frontmostApplication(previous: baseline.frontmostBundleIdentifier, current: current)
        baseline.frontmostBundleIdentifier = current
      }
      self.baseline = baseline
      let matches = ApplicationTriggers.match(transition, rules: rules, enabledModeIDs: enabledModeIDs())
      if !matches.isEmpty { onMatches(matches) }
    }
  }
}
