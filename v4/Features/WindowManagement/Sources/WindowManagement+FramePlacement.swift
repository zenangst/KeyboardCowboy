import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

extension WindowManagement {
  public enum FramePlacementError: Error, Equatable {
    case settlingTimedOut
  }

  static func placeFocusedWindow(
    in pid: pid_t, using accessibility: AccessibilitySystem.Client,
    requestedFrame: @escaping @Sendable (CGRect) -> CGRect?,
  ) async throws -> FrameResult? {
    try await placeIdentifiedFocusedWindow(in: pid, using: accessibility) { _, original, _ in
      requestedFrame(original)
    }?.frame
  }

  static func placeIdentifiedFocusedWindow(
    in pid: pid_t, using accessibility: AccessibilitySystem.Client,
    requestedFrame: @escaping @Sendable (CGWindowID, CGRect, CGRect) -> CGRect?,
  ) async throws -> (id: CGWindowID, frame: FrameResult)? {
    let isAppActive: @Sendable () -> Bool = {
      NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
    }
    guard pid > 0, pid != getpid(), isAppActive() else { return nil }

    let move = try await accessibility.withApplication(processIdentifier: pid) { session -> Move? in
      guard let window = try session.focusedWindow(),
            let id = try session.windowIDCandidate(for: window) else { return nil }
      let original = try session.frame(of: window)
      guard let onScreen = compositorFrame(id: id, owner: pid),
            let requested = requestedFrame(id, original, onScreen),
            try session.focusedWindow() == window, isAppActive() else { return nil }
      // AX may already report a pending destination.
      if !Operation.FrameSettling.matchesOrigin(onScreen, requested.origin) {
        try session.write(.position, value: requested.origin, to: window)
      }
      return Move(id: id, original: original, requested: requested)
    }
    guard let move else { return nil }

    return try await Operation.FrameSettling(origin: move.requested.origin).resizeWhenSettled(
      sample: { isAppActive() ? compositorFrame(id: move.id, owner: pid) : nil },
      resize: {
        try await accessibility.withApplication(processIdentifier: pid) { session in
          guard let window = try session.focusedWindow(),
                try session.windowIDCandidate(for: window) == move.id else { return nil }
          let current = try session.frame(of: window)
          guard try session.focusedWindow() == window, isAppActive(),
                let onScreen = compositorFrame(id: move.id, owner: pid),
                Operation.FrameSettling.matchesOrigin(onScreen, move.requested.origin) else { return nil }
          if current.size != move.requested.size {
            try session.write(.size, value: move.requested.size, to: window)
          }
          let frame = try FrameResult(original: move.original, requested: move.requested, observed: session.frame(of: window))
          return (id: move.id, frame: frame)
        }
      },
    )
  }
}

private struct Move: Sendable {
  let id: CGWindowID
  let original: CGRect
  let requested: CGRect
}

private func compositorFrame(id: CGWindowID, owner: pid_t) -> CGRect? {
  guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
    as? [[String: Any]] else { return nil }
  let matches = rows.filter { ($0[kCGWindowNumber as String] as? CGWindowID) == id }
  guard matches.count == 1, (matches[0][kCGWindowOwnerPID as String] as? pid_t) == owner,
        let bounds = matches[0][kCGWindowBounds as String] as? [String: Any] else { return nil }
  return CGRect(dictionaryRepresentation: bounds as CFDictionary)
}
