public extension Workspaces {
  @MainActor
  final class Executor<Snapshot: Sendable> {
    public enum Outcome: Equatable, Sendable {
      case completed
      case noPreviousWorkspace
      case emptyStage
      case alreadyActivating
    }

    public private(set) var current: SavedWorkspace?
    public private(set) var previous: SavedWorkspace?

    private var activating = false
    private let captureSnapshot: @MainActor () async throws -> Snapshot
    private let runChild: @MainActor (Step, Snapshot) async throws -> Void
    private let runTiling: @MainActor (Tiling, Snapshot) async throws -> Void
    private let resetFocus: @MainActor () async -> Void
    private let sleep: @MainActor (Duration) async throws -> Void

    /// `runChild` must start with empty runtime variables and discard child
    /// state. `runTiling` is direct: do not toggle Fill or dispatch it as a child.
    public init(
      captureSnapshot: @escaping @MainActor () async throws -> Snapshot,
      runChild: @escaping @MainActor (Step, Snapshot) async throws -> Void,
      runTiling: @escaping @MainActor (Tiling, Snapshot) async throws -> Void,
      resetFocus: @escaping @MainActor () async -> Void = {},
      sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    ) {
      self.captureSnapshot = captureSnapshot
      self.runChild = runChild
      self.runTiling = runTiling
      self.resetFocus = resetFocus
      self.sleep = sleep
    }

    public func activate(
      _ workspace: SavedWorkspace, input: ActivationInput, parentSnapshot: Snapshot,
    ) async throws -> Outcome {
      try await activate(workspace, input: input, parentSnapshot: parentSnapshot, returning: false)
    }

    public func activatePrevious(input: ActivationInput, parentSnapshot: Snapshot) async throws -> Outcome {
      try Task.checkCancellation()
      guard !activating else { return .alreadyActivating }
      guard let previous else { return .noPreviousWorkspace }
      return try await activate(previous, input: input, parentSnapshot: parentSnapshot, returning: true)
    }

    private func activate(
      _ workspace: SavedWorkspace, input: ActivationInput, parentSnapshot: Snapshot, returning: Bool,
    ) async throws -> Outcome {
      try Task.checkCancellation()
      guard !activating else { return .alreadyActivating }
      activating = true
      defer { activating = false }

      // Commit intent before effects, as v3 does. Failed effects do not roll back history.
      if current?.id != workspace.id { previous = current }
      current = workspace
      let steps = workspace.workspace.expand(
        catalog: input.catalog, runningApplications: input.runningApplications, windows: input.windows,
        frontmostBundleIdentifier: input.frontmostBundleIdentifier,
        dynamicBundleIdentifiers: input.membership.bundleIdentifiers(for: workspace.id),
        stageManagerEnabled: input.stageManagerEnabled, onlyUnhide: returning ? true : nil,
      )
      if steps.isEmpty, input.stageManagerEnabled { return .emptyStage }

      do {
        for step in steps {
          try Task.checkCancellation()
          if case let .tiling(tiling) = step {
            if !returning { try await runTiling(tiling, parentSnapshot) }
          } else {
            let snapshot = try await captureSnapshot()
            try Task.checkCancellation()
            try await runChild(step, snapshot)
            try Task.checkCancellation()
            if case let .hideAllApps(_, delay?) = step, delay > 0 {
              try await sleep(.milliseconds(delay))
            }
          }
        }
        try Task.checkCancellation()
      } catch {
        if error is CancellationError || Task.isCancelled {
          await resetFocus()
          throw CancellationError()
        }
        throw error
      }
      await resetFocus()
      try Task.checkCancellation()
      return .completed
    }
  }
}
