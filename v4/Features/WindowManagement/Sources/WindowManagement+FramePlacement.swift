import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

extension WindowManagement {
  public enum FramePlacementError: Error, Equatable {
    case settlingTimedOut
  }

  enum PlacementRequest: Equatable, Sendable {
    case place(CGRect)
    case restore(CGRect)

    var frame: CGRect {
      switch self {
      case .place(let frame), .restore(let frame): frame
      }
    }
  }

  static func placeFocusedWindow(
    in pid: pid_t, using accessibility: AccessibilitySystem.Client,
    requestedFrame: @escaping @Sendable (CGRect) -> CGRect?,
  ) async throws -> FrameResult? {
    try await placeIdentifiedFocusedWindow(in: pid, using: accessibility) { _, original, _ in
      requestedFrame(original).map(PlacementRequest.place)
    }?.frame
  }

  static func placeIdentifiedFocusedWindow(
    in pid: pid_t, using accessibility: AccessibilitySystem.Client,
    request: @escaping @Sendable (CGWindowID, CGRect, CGRect) -> PlacementRequest?,
  ) async throws -> (id: CGWindowID, request: PlacementRequest, frame: FrameResult)? {
    let isAppActive: @Sendable () -> Bool = {
      NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
    }
    guard pid > 0, pid != getpid(), isAppActive() else { return nil }

    let placement = try await accessibility.withApplication(processIdentifier: pid) { session -> Placement? in
      guard let window = try session.focusedWindow(),
            let id = try session.windowIDCandidate(for: window) else { return nil }
      let original = try session.frame(of: window)
      guard let onScreen = compositorFrame(id: id, owner: pid),
            let request = request(id, original, onScreen),
            try session.focusedWindow() == window, isAppActive() else { return nil }
      let requested = request.frame
      // AX may already report a pending destination.
      let needsMove = !Operation.FrameSettling.matchesOrigin(onScreen, requested.origin)
      if case .restore = request, needsMove, requested.size != original.size,
         requested.width <= original.width, requested.height <= original.height {
        // Moving the still-large filled window can span displays and affect
        // the size the window server allows at the restore position.
        try session.write(.size, value: requested.size, to: window)
        let resized = try session.frame(of: window)
        return Placement(id: id, original: original, request: request, resized: resized)
      }
      if needsMove {
        try session.write(.position, value: requested.origin, to: window)
      }
      return Placement(id: id, original: original, request: request, resized: nil)
    }
    guard let placement else { return nil }

    let settling = Operation.FrameSettling(origin: placement.resized?.origin ?? placement.requested.origin,
                                           size: placement.resized?.size)
    return try await settling.whenSettled(
      sample: { isAppActive() ? compositorFrame(id: placement.id, owner: pid) : nil },
      apply: {
        try await accessibility.withApplication(processIdentifier: pid) { session in
          guard let window = try session.focusedWindow(),
                try session.windowIDCandidate(for: window) == placement.id else { return nil }
          let current = try session.frame(of: window)
          guard try session.focusedWindow() == window, isAppActive(),
                let onScreen = compositorFrame(id: placement.id, owner: pid), settling.matches(onScreen) else { return nil }
          if let resized = placement.resized {
            guard current == resized else { return nil }
            if !Operation.FrameSettling.matchesOrigin(onScreen, placement.requested.origin) {
              try session.write(.position, value: placement.requested.origin, to: window)
            }
          } else if current.size != placement.requested.size {
            try session.write(.size, value: placement.requested.size, to: window)
          }
          let frame = try FrameResult(original: placement.original, requested: placement.requested, observed: session.frame(of: window))
          return (id: placement.id, request: placement.request, frame: frame)
        }
      },
    )
  }
}

private struct Placement: Sendable {
  let id: CGWindowID
  let original: CGRect
  let request: WindowManagement.PlacementRequest
  let resized: CGRect?

  var requested: CGRect { request.frame }
}

private func compositorFrame(id: CGWindowID, owner: pid_t) -> CGRect? {
  guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
    as? [[String: Any]] else { return nil }
  let matches = rows.filter { ($0[kCGWindowNumber as String] as? CGWindowID) == id }
  guard matches.count == 1, (matches[0][kCGWindowOwnerPID as String] as? pid_t) == owner,
        let bounds = matches[0][kCGWindowBounds as String] as? [String: Any] else { return nil }
  return CGRect(dictionaryRepresentation: bounds as CFDictionary)
}
