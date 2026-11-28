import ApplicationCatalog
import WindowTilingFeature

public extension AppFocus {
  @MainActor
  struct Executor {
    public enum Outcome: Equatable, Sendable {
      case completed, unavailableApplication, activationTimedOut, noEligibleWindows, focusChanged
    }

    private let snapshot: @MainActor () -> Snapshot
    private let open: @MainActor (ApplicationCatalog.Application) async throws -> Void
    private let activateAll: @MainActor (Snapshot.Process) async throws -> Void
    private let hideOtherApps: @MainActor (Snapshot.Process) async throws -> Void
    private let tile: @MainActor (WindowTiling.Action, Snapshot.Process) async throws -> Void
    private let sleep: @MainActor (Duration) async throws -> Void

    /// Adapters own native effects; revalidate the supplied process before a
    /// side effect if the adapter suspends. Tiling is direct, not a Fill toggle.
    public init(
      snapshot: @escaping @MainActor () -> Snapshot,
      open: @escaping @MainActor (ApplicationCatalog.Application) async throws -> Void,
      activateAll: @escaping @MainActor (Snapshot.Process) async throws -> Void,
      hideOtherApps: @escaping @MainActor (Snapshot.Process) async throws -> Void,
      tile: @escaping @MainActor (WindowTiling.Action, Snapshot.Process) async throws -> Void,
      sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    ) {
      self.snapshot = snapshot
      self.open = open
      self.activateAll = activateAll
      self.hideOtherApps = hideOtherApps
      self.tile = tile
      self.sleep = sleep
    }

    public func run(
      _ request: Request, catalog: [ApplicationCatalog.Application],
      current: ApplicationCatalog.Application? = nil, previous: ApplicationCatalog.Application? = nil,
    ) async throws -> Outcome {
      try Task.checkCancellation()
      guard let app = request.resolve(catalog: catalog, current: current, previous: previous) else {
        return .unavailableApplication
      }
      let initial = snapshot()
      let bundle = app.bundleIdentifier
      let running = initial.running.first { $0.bundleIdentifier == bundle }
      let hasWindows = running.map { !initial.eligibleWindows(of: $0.pid).isEmpty } ?? false
      if (request.targetsCurrent && request.createNewWindow) || !hasWindows {
        try await open(app)
        try Task.checkCancellation()
      }
      if let process = snapshot().running.first(where: { $0.bundleIdentifier == bundle && $0.pid > 0 }) {
        try await activateAll(process)
        try Task.checkCancellation()
      }

      guard let active = try await wait(interval: .milliseconds(10), until: { state in
        state.frontmost.map { $0.bundleIdentifier == bundle && $0.pid > 0 } ?? false
      }), let target = active.frontmost else { return .activationTimedOut }

      guard let ready = try await wait(interval: .milliseconds(50), until: { state in
        state.frontmost != target || !state.eligibleWindows(of: target.pid).isEmpty
      }) else { return .noEligibleWindows }
      guard ready.frontmost == target else { return .focusChanged }
      if ready.running.contains(where: { $0.bundleIdentifier == "bobko.aerospace" }) { return .completed }

      try Task.checkCancellation()
      if request.hideOtherApps {
        try await hideOtherApps(target)
        try Task.checkCancellation()
      }
      if let tiling = request.tiling {
        let fresh = snapshot()
        guard fresh.frontmost == target else { return .focusChanged }
        let windows = fresh.eligibleWindows(of: target.pid)
        guard let action = AppFocus.layout(tiling, windows: windows, snapshot: fresh) else { return .noEligibleWindows }
        try await tile(action, target)
        try Task.checkCancellation()
      }
      return .completed
    }

    private func wait(interval: Duration, until condition: (Snapshot) -> Bool) async throws -> Snapshot? {
      for attempt in 0 ... 10 {
        try Task.checkCancellation()
        let state = snapshot()
        if condition(state) { return state }
        if attempt < 10 { try await sleep(interval) }
      }
      return nil
    }
  }
}
