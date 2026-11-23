#if DEBUG || WINDOW_FOCUS_VALIDATION
import AccessibilitySystem
import CoreGraphics
import Darwin

public enum WindowFocus {
  /// Cycles within the active app in ascending CG ID order, independent of
  /// Z-order changes after a raise. No IDs are retained between calls.
  @discardableResult
  public static func nextWindow(
    in processIdentifier: pid_t,
    using accessibility: AccessibilitySystem.Client = .init(),
    isAppActive: @escaping @Sendable () -> Bool,
  ) async throws -> Bool {
    // AX can execute a same-process action inline on this off-main worker.
    guard processIdentifier > 0, processIdentifier != getpid(), isAppActive() else { return false }

    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try nextWindow(
        in: processIdentifier,
        isAppActive: isAppActive,
        focusedWindow: session.focusedWindow,
        windows: session.windows,
        candidates: session.debugWindowIDCandidates(for:),
        onScreenOwners: onScreenOwners,
        raise: { try session.perform(.raise, on: $0) },
      )
    }
  }

  static func nextWindow<Window: Equatable>(
    in pid: pid_t,
    isAppActive: () -> Bool,
    focusedWindow: () throws -> Window?,
    windows: () throws -> [Window],
    candidates: ([Window]) throws -> [CGWindowID?]?,
    onScreenOwners: () -> [CGWindowID: Set<pid_t>]?,
    raise: (Window) throws -> Void,
  ) throws -> Bool {
    guard let focused = try focusedWindow() else { return false }

    let windows = try windows()
    guard let focusedIndex = windows.firstIndex(of: focused),
          let ids = try candidates(windows), ids.count == windows.count,
          let focusedID = ids[focusedIndex],
          let onScreen = onScreenOwners() else { return false }

    let idCounts = Dictionary(ids.compactMap { $0 }.map { ($0, 1) }, uniquingKeysWith: +)
    let eligible = zip(ids, windows)
      .compactMap { id, window -> (id: CGWindowID, window: Window)? in
        guard let id, id != kCGNullWindowID, idCounts[id] == 1, onScreen[id] == [pid] else { return nil }

        return (id, window)
      }
      .sorted { $0.id < $1.id }
    guard eligible.count > 1, let cursor = eligible.firstIndex(where: { $0.id == focusedID }) else { return false }

    let next = eligible[(cursor + 1) % eligible.count]

    // Do not use the old snapshot if focus, either AX association, or current
    // on-screen ownership changed. Never retarget or retry this invocation.
    guard try focusedWindow() == focused,
          try candidates([focused, next.window]) == [focusedID, next.id],
          let fresh = onScreenOwners(), fresh[focusedID] == [pid], fresh[next.id] == [pid],
          isAppActive() else { return false }

    try raise(next.window)
    return true
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
#endif
