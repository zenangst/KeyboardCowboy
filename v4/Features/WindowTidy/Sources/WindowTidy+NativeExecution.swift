import AccessibilitySystem
import AppKit
import CoreGraphics
import WindowTilingFeature

public extension WindowTidy {
  /// Applies an explicit, caller-scoped inventory; never invokes a group menu
  /// action. A failing AX write can leave a partial move and is not rolled back.
  /// Focus restoration does not activate an app the user has switched away from.
  @MainActor static func runNative(
    _ request: Request, inventory: @escaping @MainActor () -> [Window],
    visibleFrame: CGRect, spacing: CGFloat = 0, using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Executor.Result {
    try Task.checkCancellation()
    let effects = NativeEffects(accessibility: accessibility)
    let plan = WindowTidy.plan(windows: inventory(), visibleFrame: visibleFrame, spacing: spacing, rules: request.rules)
    guard let anchor = plan.restoreFocus else { return .init(applied: [], skipped: [], restoredFocus: false) }
    let anchorWasFocused = try await effects.hasFocus(anchor)
    return try await Executor(
      inventory: inventory,
      apply: { step in
        guard let frame = WindowTiling.targetFrame(
          for: step.action, window: step.window.frame, in: visibleFrame, margin: spacing,
        ) else { return false }
        return try await effects.move(step.window, to: frame)
      },
      restore: { window in
        guard anchorWasFocused else { return false }
        return try await effects.restore(window)
      },
    ).run(plan, visibleFrame: visibleFrame)
  }
}

private extension WindowTidy {
  struct NativeEffects {
    let accessibility: AccessibilitySystem.Client

    func move(_ window: Window, to frame: CGRect) async throws -> Bool {
      let before = window.frame
      // Shrink first when necessary so the window fits at the destination.
      // Move before growing: AppKit can clamp a resize to the space remaining
      // at the old origin. Wait for each change before issuing the next one.
      let size = CGSize(width: min(before.width, frame.width), height: min(before.height, frame.height))
      let smaller = CGRect(origin: before.origin, size: size)
      let moved = CGRect(origin: frame.origin, size: size)
      guard try await writeFrame(window, from: before, to: smaller, positionOnly: false),
            try await writeFrame(window, from: smaller, to: moved, positionOnly: true) else { return false }
      return try await writeFrame(window, from: moved, to: frame, positionOnly: false)
    }

    private func writeFrame(_ window: Window, from before: CGRect, to frame: CGRect, positionOnly: Bool) async throws -> Bool {
      if before == frame {
        return Self.onScreenFrame(window).map { Self.matches($0, frame) } == true
      }
      let accepted = try await accessibility.withApplication(processIdentifier: window.owner) { session in
        guard let element = try Self.exactElement(window, in: session),
              Self.matches(try session.frame(of: element), before),
              let actual = Self.onScreenFrame(window), Self.matches(actual, before) else { return false }
        if positionOnly {
          try session.write(.position, value: frame.origin, to: element)
        } else {
          try session.write(.size, value: frame.size, to: element)
        }
        return true
      }
      guard accepted else { return false }
      for _ in 0 ..< 10 {
        try Task.checkCancellation()
        guard let actual = Self.onScreenFrame(window) else { return false }
        if Self.matches(actual, frame) { return true }
        try await Task.sleep(for: .milliseconds(50))
      }
      return false
    }

    func restore(_ window: Window) async throws -> Bool {
      guard Self.isFrontmost(window) else { return false }
      let accepted = try await accessibility.withApplication(processIdentifier: window.owner) { session in
        guard let target = try Self.exactElement(window, in: session),
              Self.onScreenFrame(window) != nil, Self.isFrontmost(window) else { return false }
        if try !Self.isFocused(window, in: session) {
          try session.perform(.raise, on: target)
        }
        return true
      }
      guard accepted else { return false }
      for _ in 0 ..< 10 {
        guard Self.isFrontmost(window), Self.onScreenFrame(window) != nil else { return false }
        if try await hasFocus(window) { return true }
        try await Task.sleep(for: .milliseconds(50))
      }
      return false
    }

    func hasFocus(_ window: Window) async throws -> Bool {
      guard Self.isFrontmost(window), Self.onScreenFrame(window) != nil else { return false }
      return try await accessibility.withApplication(processIdentifier: window.owner) { session in
        try Self.isFocused(window, in: session) && Self.isFrontmost(window) && Self.onScreenFrame(window) != nil
      }
    }

    private static func exactElement(
      _ window: Window, in session: AccessibilitySystem.Session,
    ) throws -> AccessibilitySystem.Element? {
      guard window.owner != getpid() else { return nil }
      let matches = try session.windows().filter { try session.windowIDCandidate(for: $0) == window.id }
      return matches.count == 1 ? matches.first : nil
    }

    private static func isFocused(_ window: Window, in session: AccessibilitySystem.Session) throws -> Bool {
      guard let focused = try session.focusedWindow() else { return false }
      return try session.windowIDCandidate(for: focused) == window.id
    }

    private static func isFrontmost(_ window: Window) -> Bool {
      guard let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier == window.owner else { return false }
      return window.bundleIdentifier == nil || app.bundleIdentifier == window.bundleIdentifier
    }

    private static func onScreenFrame(_ window: Window) -> CGRect? {
      guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
              as? [[String: Any]] else { return nil }
      let matches = rows.filter {
        $0[kCGWindowNumber as String] as? CGWindowID == window.id
          && $0[kCGWindowOwnerPID as String] as? pid_t == window.owner
      }
      guard matches.count == 1, let row = matches.first,
            let bounds = row[kCGWindowBounds as String] as? [String: Any] else { return nil }
      return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    private static func matches(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
      abs(lhs.minX - rhs.minX) <= 1 && abs(lhs.minY - rhs.minY) <= 1
        && abs(lhs.maxX - rhs.maxX) <= 1 && abs(lhs.maxY - rhs.maxY) <= 1
    }
  }
}
