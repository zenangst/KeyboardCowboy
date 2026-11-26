import AccessibilitySystem
import AppKit
import CoreGraphics
import WindowTilingFeature

extension Operation {
  @MainActor
  struct FillAllWindows {
    struct Display {
      let visibleBounds: CGRect
      let spacing: CGFloat
    }

    struct Window: Sendable {
      let id: CGWindowID
      let pid: Int32
      let bounds: CGRect
    }

    let display: @MainActor () -> Display?
    let windows: @MainActor () -> [Window]
    let fill: @MainActor (Window, CGRect?) async throws -> Void

    func callAsFunction() async throws {
      try Task.checkCancellation()
      guard let display = display() else { return }
      let targets = windows().reversed().filter { $0.bounds.intersects(display.visibleBounds) }
      let filled = display.visibleBounds.insetBy(dx: display.spacing, dy: display.spacing)
      for (index, window) in targets.enumerated() {
        try Task.checkCancellation()
        // The last enumerated window is deliberately attempted even if already filled.
        try await fill(window, index == targets.count - 1 ? nil : filled)
      }
    }

    static func live() -> Self {
      let accessibility = AccessibilitySystem.Client()
      return Self(display: {
        guard let screen = NSScreen.main, let primary = NSScreen.screens.first else { return nil }
        let frame = screen.visibleFrame
        let bounds = CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY,
                            width: frame.width, height: frame.height)
        let settings = UserDefaults(suiteName: "com.apple.WindowManager")
        let spacing: CGFloat
        if settings?.bool(forKey: "EnableTiledWindowMargins") == true {
          spacing = max(0, (settings?.object(forKey: "TiledWindowSpacing") as? NSNumber)
            .map { CGFloat($0.doubleValue) } ?? 8)
        } else {
          spacing = 0
        }
        return Display(visibleBounds: bounds, spacing: spacing)
      }, windows: visibleWindows, fill: { window, skipFrame in
        guard window.pid > 0, window.pid != ProcessInfo.processInfo.processIdentifier,
              let app = NSRunningApplication(processIdentifier: window.pid), !app.isTerminated
        else { return }

        let prepared = try await accessibility.withApplication(processIdentifier: window.pid) { session in
          let target: AccessibilitySystem.Element?
          do {
            target = try session.windows().first { try session.windowIDCandidate(for: $0) == window.id }
          } catch {
            try Task.checkCancellation()
            return false
          }
          guard let target, !app.isTerminated,
                visibleWindows().contains(where: { $0.id == window.id && $0.pid == window.pid })
          else { return false }
          if let skipFrame, (try? session.frame(of: target)) == skipFrame { return false }

          try session.checkpoint()
          try session.write(.main, value: true, to: target)
          return true
        }
        try Task.checkCancellation()
        guard prepared, !app.isTerminated else { return }
        if NSWorkspace.shared.frontmostApplication?.isEqual(app) != true {
          guard app.activate(options: []) else { return }
          for _ in 0 ..< 10 {
            if NSWorkspace.shared.frontmostApplication?.isEqual(app) == true { break }
            try await Task.sleep(for: .milliseconds(10))
          }
        }
        _ = try await WindowTiling.execute(.fill, onFocusedWindow: window.id, of: app, using: accessibility)
      })
    }

    nonisolated private static func visibleWindows() -> [Window] {
      let rows = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID)
        as? [[String: Any]] ?? []
      let excluded = ["borders", "WindowManager", "Window Server"]
      return rows.compactMap { row in
        guard let id = row[kCGWindowNumber as String] as? CGWindowID, id != kCGNullWindowID,
              let pid = row[kCGWindowOwnerPID as String] as? Int32,
              let alpha = row[kCGWindowAlpha as String] as? Double, alpha > 0,
              !excluded.contains(row[kCGWindowOwnerName as String] as? String ?? ""),
              let bounds = row[kCGWindowBounds as String] as? [String: Any],
              let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
              frame.width > 300, frame.height > 200 else { return nil }

        return Window(id: id, pid: pid, bounds: frame)
      }
    }
  }
}
