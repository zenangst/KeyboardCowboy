import AppKit
import Commands
import CoreGraphics

extension Operation {
  @MainActor
  struct HideAllApps {
    struct Window {
      let id: Int
      let pid: Int32
      let owner: String
      let frame: CGRect
      let alpha: Double
    }

    struct Application {
      let pid: Int32
      let bundleID: String?
      let bundleURL: URL?
      let isRegular: Bool
      let isHidden: @MainActor () -> Bool
      let hide: @MainActor () -> Void
    }

    let screens: @MainActor () -> [CGRect]
    let applications: @MainActor () -> [Application]
    let windows: @MainActor () -> [Window]
    let ownBundleID: String?
    let ownPID: Int32
    let pause: @MainActor () async throws -> Void

    func callAsFunction(_ commands: [Command.Application]) async throws {
      try Task.checkCancellation()
      let frames = screens()
      guard let main = frames.first else { return }

      let apps = applications()
      let opens = commands.filter { $0.action == .open || $0.action == .unhide }
      let protectedIDs = Set(opens.map(\.application.bundleIdentifier) + [ownBundleID].compactMap { $0 })
      let finder = "com.apple.finder"
      let hideFinderFirst = !opens.isEmpty && opens.allSatisfy { $0.action == .unhide }
        && !protectedIDs.contains(finder)
      let earlyFinder = hideFinderFirst ? apps.first { $0.bundleID == finder && $0.pid != ownPID } : nil
      try Task.checkCancellation()
      earlyFinder?.hide()

      let inventory = windows()
      let targetID = commands.last?.application.bundleIdentifier
      let targetPID = targetID.flatMap { id in apps.first { $0.bundleID == id }?.pid }
      let frame = targetPID.flatMap { pid in
        frames.first { visiblePIDs(in: $0, windows: inventory).contains(pid) }
      } ?? main
      let visible = visiblePIDs(in: frame, windows: inventory)
      let candidates = apps.filter { app in
        guard app.pid != ownPID, app.pid != earlyFinder?.pid, visible.contains(app.pid),
              app.isRegular, !app.isHidden(),
              let url = app.bundleURL, url.pathExtension == "app", !url.path.contains("Frameworks/")
        else { return false }

        return app.bundleID.map { $0 != targetID && !protectedIDs.contains($0) } ?? true
      }

      for app in candidates {
        try Task.checkCancellation()
        app.hide()
        for _ in 0 ..< 10 {
          try Task.checkCancellation()
          if app.isHidden() { break }
          try await pause()
        }
      }

      // Only wait for windows owned by apps we attempted to hide. A protected
      // app need not have any windows, and unrelated windows may remain visible.
      let attempted = Set(candidates.map(\.pid))
      guard !attempted.isEmpty else { return }

      for _ in 0 ..< 100 {
        try Task.checkCancellation()
        if visiblePIDs(in: frame, windows: windows()).isDisjoint(with: attempted) { return }
        try await pause()
      }
    }

    private func visiblePIDs(in frame: CGRect, windows: [Window]) -> Set<Int32> {
      let excluded = ["borders", "WindowManager", "Window Server"]
      return Set(windows.lazy
        .filter {
          $0.id > 0 && !excluded.contains($0.owner) && $0.frame.width > 300 && $0.frame.height > 200
            && $0.alpha == 1 && $0.frame.intersects(frame)
        }
        .map(\.pid))
    }

    static func live(limitingTo processIdentifiers: Set<Int32>? = nil) -> Self {
      Self(
        screens: {
          guard let main = NSScreen.main, let primary = NSScreen.screens.first else { return [] }

          return ([main] + NSScreen.screens.filter { $0 != main }).map { screen in
            let frame = screen.visibleFrame
            return CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY,
                          width: frame.width, height: frame.height)
          }
        },
        applications: {
          NSWorkspace.shared.runningApplications.filter {
            !$0.isTerminated && (processIdentifiers?.contains($0.processIdentifier) ?? true)
          }.map { app in
            Application(pid: app.processIdentifier, bundleID: app.bundleIdentifier, bundleURL: app.bundleURL,
                        isRegular: app.activationPolicy == .regular, isHidden: { app.isHidden },
                        hide: { _ = app.hide() })
          }
        },
        windows: {
          let rows = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] ?? []
          return rows.compactMap { row in
            guard let id = row[kCGWindowNumber as String] as? Int,
                  let pid = row[kCGWindowOwnerPID as String] as? Int32,
                  let bounds = row[kCGWindowBounds as String] as? [String: Any],
                  let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
                  let alpha = row[kCGWindowAlpha as String] as? Double else { return nil }

            return Window(id: id, pid: pid, owner: row[kCGWindowOwnerName as String] as? String ?? "",
                          frame: frame, alpha: alpha)
          }
        },
        ownBundleID: Bundle.main.bundleIdentifier,
        ownPID: ProcessInfo.processInfo.processIdentifier,
        pause: { try await Task.sleep(for: .milliseconds(10)) },
      )
    }
  }
}
