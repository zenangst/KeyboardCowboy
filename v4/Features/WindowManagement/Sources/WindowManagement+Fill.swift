import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

public extension WindowManagement {
  /// Fills the active application's focused window within the display's usable
  /// area, inset by `padding`. Does not enter native fullscreen or save a
  /// restore frame. Returns nil if no target can be verified. A move that
  /// already happened is not rolled back.
  @discardableResult
  static func fillFocusedWindow(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat = 0,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    let pid = processIdentifier
    let isAppActive: @Sendable () -> Bool = {
      NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
    }
    let fill = try Operation.Fill(displays: displays, padding: padding)
    guard pid > 0, pid != getpid(), !displays.isEmpty, isAppActive() else { return nil }

    let move = try await accessibility.withApplication(processIdentifier: pid) { session -> Move? in
      guard let window = try session.focusedWindow(),
            let id = try session.windowIDCandidate(for: window) else { return nil }
      let original = try session.frame(of: window)
      guard let requested = fill.requestedFrame(for: original),
            try session.focusedWindow() == window, isAppActive(),
            let onScreen = compositorFrame(id: id, owner: pid) else { return nil }
      // Use the actual on-screen position, since AX may already report a pending destination.
      if !Operation.SettledFill.matchesOrigin(onScreen, requested.origin) {
        try session.write(.position, value: requested.origin, to: window)
      }
      return Move(id: id, original: original, requested: requested)
    }
    guard let move else { return nil }

    return try await Operation.SettledFill(origin: move.requested.origin).resizeWhenSettled(
      sample: { isAppActive() ? compositorFrame(id: move.id, owner: pid) : nil },
      resize: {
        try await accessibility.withApplication(processIdentifier: pid) { session in
          guard let window = try session.focusedWindow(),
                try session.windowIDCandidate(for: window) == move.id else { return nil }
          let current = try session.frame(of: window)
          guard try session.focusedWindow() == window, isAppActive(),
                let onScreen = compositorFrame(id: move.id, owner: pid),
                Operation.SettledFill.matchesOrigin(onScreen, move.requested.origin) else { return nil }
          if current.size != move.requested.size {
            try session.write(.size, value: move.requested.size, to: window)
          }
          return try .init(original: move.original, requested: move.requested, observed: session.frame(of: window))
        }
      },
    )
  }

  enum FillError: Error, Equatable {
    case invalidPadding
    case settlingTimedOut
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
