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
    }

    private let accessibility: AccessibilitySystem.Client
    private var center = WindowFocus.CenterCycle()
    private var quarter = WindowFocus.QuarterCycle()
    private var running = false
    private let revision = OSAllocatedUnfairLock(initialState: 0)

    init(accessibility: AccessibilitySystem.Client) {
      self.accessibility = accessibility
    }

    func reset() {
      revision.withLock { $0 &+= 1 }
      center.reset()
      quarter.reset()
    }

    func callAsFunction(_ selection: Selection) async throws -> Bool {
      try Task.checkCancellation()
      guard !running, let source = NSWorkspace.shared.frontmostApplication,
            source.processIdentifier != getpid() else { return false }
      running = true
      defer { running = false }
      let stamp = revision.withLock { $0 }
      guard let focused = try await focusedID(of: source.processIdentifier),
            revision.withLock({ $0 }) == stamp, NSWorkspace.shared.frontmostApplication == source else { return false }

      let inventory = Self.inventory()
      guard inventory.contains(where: { $0.owner == source.processIdentifier && $0.window.id == focused }) else {
        return false
      }
      let windows = inventory.filter {
        guard $0.owner != getpid(), let app = NSRunningApplication(processIdentifier: $0.owner) else { return false }
        return !app.isHidden && !app.isTerminated
      }.map(\.window)
      let id: CGWindowID?
      switch selection {
      case let .center(display, visibleFrame, spacing):
        id = center.select(in: display, visibleFrame: visibleFrame, spacing: spacing, windows: windows,
                           focusedWindowID: focused)
      case let .quarter(region, display, spacing):
        center.reset()
        id = quarter.select(region, in: display, spacing: spacing, windows: windows, focusedWindowID: focused)
      }
      guard let id, let candidate = inventory.first(where: { $0.window.id == id }),
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
            return Self.isCurrent(candidate, in: target) && NSWorkspace.shared.frontmostApplication == source
              && revision.withLock { $0 } == stamp
          },
          raise: {
            try session.checkpoint()
            try session.perform(.raise, on: $0)
          },
        )
      }
      try Task.checkCancellation()
      guard raised, revision.withLock({ $0 }) == stamp, Self.isCurrent(candidate, in: target) else { return false }
      if NSWorkspace.shared.frontmostApplication != target {
        guard NSWorkspace.shared.frontmostApplication == source, target.activate(from: source) else { return false }
      }
      let observed = try await focusedID(of: candidate.owner)
      return revision.withLock { $0 } == stamp && NSWorkspace.shared.frontmostApplication == target && observed == id
    }

    private func focusedID(of pid: pid_t) async throws -> CGWindowID? {
      try await accessibility.withApplication(processIdentifier: pid) { session in
        guard let window = try session.focusedWindow() else { return nil }
        return try session.windowIDCandidate(for: window)
      }
    }

    private struct Entry: Sendable {
      let window: WindowFocus.SpatialWindow
      let owner: pid_t
    }

    private nonisolated static func isCurrent(_ candidate: Entry, in app: NSRunningApplication) -> Bool {
      guard !app.isHidden, !app.isTerminated else { return false }
      let matches = inventory().filter { $0.window.id == candidate.window.id }
      return matches.count == 1 && matches[0].owner == candidate.owner
        && matches[0].window.frame == candidate.window.frame
    }

    private nonisolated static func inventory() -> [Entry] {
      guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] else { return [] }
      return rows.compactMap { row in
        guard let id = row[kCGWindowNumber as String] as? CGWindowID, id != 0,
              let owner = row[kCGWindowOwnerPID as String] as? pid_t, owner > 0,
              let name = row[kCGWindowOwnerName as String] as? String,
              !["borders", "WindowManager", "Window Server"].contains(name),
              row[kCGWindowAlpha as String] as? Double == 1,
              let bounds = row[kCGWindowBounds as String] as? [String: Any],
              let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
              WindowFocus.SpatialWindow.isValid(frame), frame.width > 300, frame.height > 200 else { return nil }
        return Entry(window: .init(id: id, frame: frame), owner: owner)
      }
    }
  }
}
#endif
