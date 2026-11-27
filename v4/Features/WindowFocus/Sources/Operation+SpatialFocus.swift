#if DEBUG || WINDOW_FOCUS_VALIDATION
import AccessibilitySystem
import AppKit
import CoreGraphics
import os

extension Operation {
  @MainActor
  final class SpatialFocus {
    enum Selection {
      case center(CGRect, CGRect, CGFloat)
      case quarter(WindowFocus.Quarter, CGRect, CGFloat)
      case directional(DirectionalFocus)
      case spaceRing(WindowFocus.SpaceRing.Direction)

      var usesSpaceRing: Bool {
        if case .spaceRing = self { return true }
        return false
      }
    }

    private let accessibility: AccessibilitySystem.Client
    private let processIdentifiers: Set<pid_t>?
    private var center = WindowFocus.CenterCycle()
    private var quarter = WindowFocus.QuarterCycle()
    private var spaceRing = WindowFocus.SpaceRing()
    private var running = false
    private let revision = OSAllocatedUnfairLock(initialState: 0)

    init(accessibility: AccessibilitySystem.Client, processIdentifiers: Set<pid_t>? = nil) {
      self.accessibility = accessibility
      self.processIdentifiers = processIdentifiers
    }

    func reset() {
      revision.withLock { $0 &+= 1 }
      resetCycles()
      spaceRing.reset()
    }

    func callAsFunction(_ selection: Selection) async throws -> Bool {
      try Task.checkCancellation()
      guard !running, let source = NSWorkspace.shared.frontmostApplication,
            processIdentifiers?.contains(source.processIdentifier) ?? true,
            source.processIdentifier != getpid() else { return false }

      running = true
      let usesSpaceRing = selection.usesSpaceRing
      defer {
        if usesSpaceRing { spaceRing.cancelSelection() }
        running = false
      }
      let stamp = revision.withLock { $0 }
      guard let focused = try await focusedID(of: source.processIdentifier),
            revision.withLock({ $0 }) == stamp, NSWorkspace.shared.frontmostApplication == source else { return false }

      let inventory = Self.inventory(forSpaceRing: usesSpaceRing)
      let anchors = inventory.filter { $0.id == focused }
      guard anchors.count == 1, let anchor = anchors.first, anchor.owner == source.processIdentifier else {
        return false
      }

      let eligible = inventory.filter {
        guard processIdentifiers?.contains($0.owner) ?? true,
              $0.owner != getpid(), let app = NSRunningApplication(processIdentifier: $0.owner) else { return false }

        return !app.isHidden && !app.isTerminated
      }
      let id: CGWindowID?
      switch selection {
      case let .center(display, visibleFrame, spacing):
        id = center.select(in: display, visibleFrame: visibleFrame, spacing: spacing, windows: eligible.map(\.spatialWindow),
                           focusedWindowID: focused)
      case let .quarter(region, display, spacing):
        center.reset()
        id = quarter.select(region, in: display, spacing: spacing, windows: eligible.map(\.spatialWindow),
                            focusedWindowID: focused)
      case let .directional(operation):
        resetCycles()
        let candidates = eligible.map { (id: $0.id, owner: $0.owner, frame: $0.frame) }
        id = try await accessibility.withApplication(
          processIdentifier: source.processIdentifier) { [revision] session in
            try operation(
              anchorID: focused,
              candidates: candidates,
              session: session,
              isCurrent: { revision.withLock { $0 } == stamp && NSWorkspace.shared.frontmostApplication == source })
          }
      case let .spaceRing(direction):
        center.reset()
        guard eligible.contains(anchor) else { return false }
        spaceRing.update(eligible)
        spaceRing.observeFocus(windowID: focused, owner: source.processIdentifier)
        id = spaceRing.select(direction, frontmostOwner: source.processIdentifier)?.id
      }
      guard let id, let candidate = eligible.first(where: { $0.id == id }),
            let target = NSRunningApplication(processIdentifier: candidate.owner) else { return false }

      // Re-read focus before entering the target transaction. Never retarget this invocation.
      guard try await focusedID(of: source.processIdentifier) == focused,
            revision.withLock({ $0 }) == stamp, NSWorkspace.shared.frontmostApplication == source else { return false }

      let raised = try await accessibility.withApplication(processIdentifier: candidate.owner) { [revision] session in
        try RaiseVerifiedWindow.run(
          id: id, windows: session.windows, identity: session.windowIDCandidate(for:),
          isCurrent: {
            if source == target {
              guard let current = try session.focusedWindow(),
                    try session.windowIDCandidate(for: current) == focused else { return false }
            }
            let fresh = Self.inventory(forSpaceRing: usesSpaceRing)
            return Self.isCurrent(candidate, in: target, inventory: fresh)
              && Self.isCurrent(anchor, in: source, inventory: fresh)
              && NSWorkspace.shared.frontmostApplication == source && revision.withLock { $0 } == stamp
          },
          raise: {
            try session.checkpoint()
            try session.perform(.raise, on: $0)
          },
        )
      }
      try Task.checkCancellation()
      guard raised, revision.withLock({ $0 }) == stamp,
            Self.isCurrent(candidate, in: target, inventory: Self.inventory(forSpaceRing: usesSpaceRing)) else { return false }

      if NSWorkspace.shared.frontmostApplication != target {
        guard NSWorkspace.shared.frontmostApplication == source, target.activate(from: source) else { return false }
      }
      let observed = try await focusedID(of: candidate.owner)
      guard revision.withLock({ $0 }) == stamp, NSWorkspace.shared.frontmostApplication == target, observed == id
      else { return false }
      if usesSpaceRing { spaceRing.observeFocus(windowID: id, owner: candidate.owner) }
      return true
    }

    private func resetCycles() {
      center.reset()
      quarter.reset()
    }

    private func focusedID(of pid: pid_t) async throws -> CGWindowID? {
      try await accessibility.withApplication(processIdentifier: pid) { session in
        guard let window = try session.focusedWindow() else { return nil }

        return try session.windowIDCandidate(for: window)
      }
    }

    private nonisolated static func isCurrent(
      _ candidate: WindowFocus.SpaceRing.Window,
      in app: NSRunningApplication,
      inventory: [WindowFocus.SpaceRing.Window],
    ) -> Bool {
      guard !app.isHidden, !app.isTerminated else { return false }

      let matches = inventory.filter { $0.id == candidate.id }
      return matches.count == 1 && matches[0].owner == candidate.owner
        && matches[0].frame == candidate.frame
    }

    private nonisolated static func inventory(forSpaceRing: Bool) -> [WindowFocus.SpaceRing.Window] {
      guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] else { return [] }

      return rows.compactMap { row in
        guard let id = row[kCGWindowNumber as String] as? CGWindowID, id != 0,
              let owner = row[kCGWindowOwnerPID as String] as? pid_t, owner > 0,
              let name = row[kCGWindowOwnerName as String] as? String,
              let alpha = row[kCGWindowAlpha as String] as? Double,
              let bounds = row[kCGWindowBounds as String] as? [String: Any],
              let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return nil }

        let window = WindowFocus.SpaceRing.Window(id: id, owner: owner, frame: frame, alpha: alpha, ownerName: name)
        guard forSpaceRing ? window.isEligible : window.isSpatiallyEligible else { return nil }
        return window
      }
    }
  }
}
#endif
