import AccessibilitySystem
import CoreGraphics
import Darwin
#if DEBUG || WINDOW_FOCUS_VALIDATION
import OSLog
#endif

extension Operation {
  struct Cycle: Sendable {
    enum Direction: Sendable {
      case next
      case previous(WindowFocus.History?)
    }

    let accessibility: AccessibilitySystem.Client
  }
}

extension Operation.Cycle {
  func callAsFunction(
    _ direction: Direction,
    in processIdentifier: pid_t,
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    let trace: @Sendable (String) -> Void
    #if DEBUG || WINDOW_FOCUS_VALIDATION
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "WindowFocusSmoke")
    trace = { log.notice("Cycle PID \(processIdentifier, privacy: .public): \($0, privacy: .public)") }
    #else
    trace = { _ in }
    #endif
    // AX can execute a same-process action inline on this off-main worker.
    guard processIdentifier > 0, processIdentifier != getpid(), isAppActive() else {
      trace("skipped: invalid or inactive target PID")
      return false
    }

    let selection = try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try Self.run(
        direction,
        in: processIdentifier,
        isAppActive: isAppActive,
        focusedWindow: session.focusedWindow,
        windows: session.windows,
        candidates: { try $0.map { try session.windowIDCandidate(for: $0) } },
        onScreenOwners: Self.onScreenOwners,
        raise: { try session.perform(.raise, on: $0) },
        trace: trace,
      )
    }
    guard let selection else { return false }

    let observed = try await Self.observeFocus(
      from: selection.source, to: selection.target,
      isCurrent: { isAppActive() && Self.onScreenOwners()?[selection.target] == [processIdentifier] },
      focusedID: {
        try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
          guard let window = try session.focusedWindow() else { return nil }
          return try session.windowIDCandidate(for: window)
        }
      },
    )
    trace("focus observed on \(selection.target): \(observed)")
    return observed
  }

  /// Waits briefly for AX focus to catch up without raising again or retargeting.
  static func observeFocus(
    from source: CGWindowID, to target: CGWindowID, isCurrent: () -> Bool,
    focusedID: () async throws -> CGWindowID?,
    wait: () async throws -> Void = { try await Task.sleep(for: .milliseconds(40)) },
  ) async throws -> Bool {
    for attempt in 0 ... 4 {
      try Task.checkCancellation()
      guard isCurrent() else { return false }
      let actual = try await focusedID()
      try Task.checkCancellation()
      guard isCurrent() else { return false }
      if actual == target { return true }
      if let actual, actual != source { return false }
      if attempt < 4 { try await wait() }
    }
    return false
  }

  static func run<Window: Equatable>(
    _ direction: Direction,
    in pid: pid_t,
    isAppActive: () -> Bool,
    focusedWindow: () throws -> Window?,
    windows: () throws -> [Window],
    candidates: ([Window]) throws -> [CGWindowID?]?,
    onScreenOwners: () -> [CGWindowID: Set<pid_t>]?,
    raise: (Window) throws -> Void,
    trace: (String) -> Void = { _ in },
  ) throws -> (source: CGWindowID, target: CGWindowID)? {
    func skip(_ reason: String) -> (source: CGWindowID, target: CGWindowID)? {
      trace("skipped: \(reason)")
      return nil
    }

    guard let focused = try focusedWindow() else { return skip("no AX focused window") }

    let windows = try windows()
    guard let focusedIndex = windows.firstIndex(of: focused) else {
      return skip("AX focused window missing from AXWindows (\(windows.count) windows)")
    }
    guard let ids = try candidates(windows), ids.count == windows.count else {
      return skip("AX window ID lookup unavailable or incomplete")
    }
    guard let focusedID = ids[focusedIndex] else { return skip("AX focused window has no CG ID") }
    guard let onScreen = onScreenOwners() else { return skip("no on-screen CG snapshot") }

    let idCounts = Dictionary(ids.compactMap { $0 }.map { ($0, 1) }, uniquingKeysWith: +)
    let eligible = zip(ids, windows)
      .compactMap { id, window -> (id: CGWindowID, window: Window)? in
        guard let id, id != kCGNullWindowID, idCounts[id] == 1, onScreen[id] == [pid] else { return nil }

        return (id, window)
      }
      .sorted { $0.id < $1.id }
    let eligibleIDs = eligible.map(\.id)
    guard let cursor = eligible.firstIndex(where: { $0.id == focusedID }) else {
      return skip("focused ID \(focusedID) not in eligible IDs \(eligibleIDs)")
    }
    guard eligible.count > 1 else { return skip("focused ID \(focusedID) is the only eligible window") }

    let target = switch direction {
    case .next:
      eligible[(cursor + 1) % eligible.count]
    case .previous(let history):
      if let history, history.processIdentifier == pid, history.current == focusedID,
         history.previous != focusedID, let prior = eligible.first(where: { $0.id == history.previous }) {
        prior
      } else {
        eligible[(cursor + eligible.count - 1) % eligible.count]
      }
    }

    // Do not use the old snapshot if focus, either AX association, or current
    // on-screen ownership changed. Never retarget or retry this invocation.
    trace("selected \(target.id) from focused \(focusedID); eligible IDs \(eligibleIDs)")
    guard try focusedWindow() == focused else { return skip("AX focus changed before raise") }
    guard try candidates([focused, target.window]) == [focusedID, target.id] else {
      return skip("AX window ID association changed before raise")
    }
    guard let fresh = onScreenOwners(), fresh[focusedID] == [pid], fresh[target.id] == [pid] else {
      return skip("focused or target ID no longer verified on-screen")
    }
    guard isAppActive() else { return skip("app no longer active before raise") }

    try raise(target.window)
    trace("AX accepted raise of \(target.id)")
    return (focusedID, target.id)
  }

  private static func onScreenOwners() -> [CGWindowID: Set<pid_t>]? {
    guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] else { return nil }

    return rows.reduce(into: [:]) { owners, row in
      guard let id = row[kCGWindowNumber as String] as? CGWindowID,
            let owner = row[kCGWindowOwnerPID as String] as? pid_t else { return }

      owners[id, default: []].insert(owner)
    }
  }
}
