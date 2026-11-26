import AccessibilitySystem
import AppKit
import ApplicationCatalog
import CoreGraphics

extension Operation {
  @MainActor
  struct MinimizeAllWindows {
    struct Application {
      let name: String?
      let bundleID: String?
      let pid: Int32
    }

    let windowOwners: @MainActor () -> [String]
    let applications: @MainActor () -> [Application]
    let catalogBundleIDs: @MainActor () async -> Set<String>
    let pressMinimizeAll: @MainActor (Int32) async throws -> Void

    func callAsFunction(_ snapshotOwners: [String]?) async throws {
      try Task.checkCancellation()
      let owners = snapshotOwners ?? windowOwners()
      guard !owners.isEmpty else { return }

      let apps = applications()
      var seen: Set<String> = []
      let targets = owners.compactMap { owner -> (pid: Int32, bundleID: String)? in
        guard let app = apps.first(where: { $0.name == owner }), let id = app.bundleID,
              seen.insert(id).inserted else { return nil }
        return (app.pid, id)
      }
      guard !targets.isEmpty else { return }
      let catalog = await catalogBundleIDs()
      try Task.checkCancellation()
      for target in targets where catalog.contains(target.bundleID) {
        try Task.checkCancellation()
        try await pressMinimizeAll(target.pid)
      }
    }

    static func live() -> Self {
      let accessibility = AccessibilitySystem.Client()
      return Self(
        windowOwners: Self.liveWindowOwners,
        applications: {
          NSWorkspace.shared.runningApplications.filter { !$0.isTerminated }.map {
            Application(name: $0.localizedName, bundleID: $0.bundleIdentifier, pid: $0.processIdentifier)
          }
        },
        catalogBundleIDs: { Set(await ApplicationCatalog.applications().map(\.bundleIdentifier)) },
        pressMinimizeAll: { pid in
          try await accessibility.withApplication(processIdentifier: pid) { session in
            guard let menuBar = try session.menuBar() else { return }
            let item = try session.firstElement(
              under: menuBar, includingRoot: false, missingChildren: .skipNoValueOrUnsupported,
            ) { element in
              do {
                return try session.read(.title, of: element) == "Minimize All" ? .match : .descend
              } catch let error as AccessibilitySystem.Failure
                where error.kind == .noValue || error.kind == .attributeUnsupported {
                return .descend
              }
            }
            if let item { try session.perform(.press, on: item) }
          }
        },
      )
    }

    private static func liveWindowOwners() -> [String] {
      let rows = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID)
        as? [[String: Any]] ?? []
      let excluded = ["borders", "WindowManager", "Window Server"]
      let windows = rows.compactMap { row -> (owner: String, y: CGFloat)? in
        guard let owner = row[kCGWindowOwnerName as String] as? String, !excluded.contains(owner),
              let id = row[kCGWindowNumber as String] as? Int, id > 0,
              let alpha = row[kCGWindowAlpha as String] as? Double, alpha > 0,
              let bounds = row[kCGWindowBounds as String] as? [String: Any],
              let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
              frame.width > 100, frame.height > 100 else { return nil }
        return (owner, frame.minY)
      }
      return windows.sorted { $0.y < $1.y }.map(\.owner)
    }
  }
}
